"""
Async client for the Trafikverket API.
Fetches real traffic flow, situations, road conditions, and camera data.
"""
import os
import re
import ssl
import aiohttp
from typing import List, Dict, Any, Optional, Tuple

API_KEY = os.environ.get("TRAFIKVERKET_API_KEY", "2144ed5001d741c9ac53511775f64336")
API_URL = "https://api.trafikinfo.trafikverket.se/v2/data.json"

# SSL workaround for Python 3.9 on macOS (LibreSSL 2.8.3)
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE


def _parse_wgs84_point(geometry: Any) -> Optional[Tuple[float, float]]:
    """Parse WGS84 POINT(lon lat) or first point of LINESTRING to (lat, lon) tuple."""
    if geometry is None:
        return None
    s = str(geometry)
    m = re.search(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', s)
    if m:
        lon, lat = float(m.group(1)), float(m.group(2))
        return (lat, lon)
    # Try LINESTRING — take midpoint
    m = re.search(r'LINESTRING\s*\((.+)\)', s)
    if m:
        points_str = m.group(1)
        pairs = [p.strip().split() for p in points_str.split(',')]
        if pairs:
            mid = pairs[len(pairs) // 2]
            if len(mid) >= 2:
                return (float(mid[1]), float(mid[0]))
    return None


def _bbox_value(bbox: Dict[str, float]) -> str:
    """Build WITHIN box value string: 'minlon minlat, maxlon maxlat'."""
    return f"{bbox['min_lon']} {bbox['min_lat']}, {bbox['max_lon']} {bbox['max_lat']}"


def _point_in_bbox(lat: float, lon: float, bbox: Dict[str, float]) -> bool:
    """Check if a point falls within a bounding box."""
    return (bbox["min_lat"] <= lat <= bbox["max_lat"] and
            bbox["min_lon"] <= lon <= bbox["max_lon"])


async def _request(xml_body: str) -> Dict[str, Any]:
    """Send a request to the Trafikverket API."""
    async with aiohttp.ClientSession() as session:
        async with session.post(
            API_URL,
            data=xml_body,
            headers={"Content-Type": "text/xml"},
            ssl=_ssl_ctx,
            timeout=aiohttp.ClientTimeout(total=15),
        ) as resp:
            if resp.status != 200:
                text = await resp.text()
                print(f"Trafikverket API Error ({resp.status}): {text}")
                resp.raise_for_status()
            return await resp.json(content_type=None)


async def fetch_traffic_flow(bbox: Dict[str, float]) -> List[Dict[str, Any]]:
    """Fetch real-time traffic flow data within a bounding box."""
    box_val = _bbox_value(bbox)
    xml = f"""
    <REQUEST>
      <LOGIN authenticationkey="{API_KEY}" />
      <QUERY objecttype="TrafficFlow" schemaversion="1.4" limit="50">
        <FILTER>
          <WITHIN name="Geometry.WGS84" shape="box" value="{box_val}" />
        </FILTER>
        <INCLUDE>AverageVehicleSpeed</INCLUDE>
        <INCLUDE>VehicleFlowRate</INCLUDE>
        <INCLUDE>Geometry.WGS84</INCLUDE>
        <INCLUDE>SiteId</INCLUDE>
        <INCLUDE>MeasurementTime</INCLUDE>
        <INCLUDE>RegionId</INCLUDE>
        <INCLUDE>SpecificLane</INCLUDE>
      </QUERY>
    </REQUEST>
    """
    try:
        data = await _request(xml)
        results = data.get("RESPONSE", {}).get("RESULT", [])
        if not results:
            return []
        flows = results[0].get("TrafficFlow", [])
        parsed = []
        for f in flows:
            geom = f.get("Geometry", {}).get("WGS84")
            coords = _parse_wgs84_point(geom)
            if coords is None:
                continue
            parsed.append({
                "lat": coords[0],
                "lon": coords[1],
                "speed": f.get("AverageVehicleSpeed"),
                "flow_rate": f.get("VehicleFlowRate"),
                "site_id": f.get("SiteId"),
                "measurement_time": f.get("MeasurementTime"),
                "lane": f.get("SpecificLane"),
                "region_id": f.get("RegionId"),
            })
        return parsed
    except Exception as e:
        print(f"TrafikverketClient: fetch_traffic_flow error: {e}")
        return []


async def fetch_situations(bbox: Dict[str, float]) -> List[Dict[str, Any]]:
    """Fetch traffic situations (incidents, closures). Filtered by bbox in code
    since Deviation.Geometry.WGS84 doesn't support WITHIN box."""
    # Fetch recent situations without geo filter, then filter by bbox
    xml = f"""
    <REQUEST>
      <LOGIN authenticationkey="{API_KEY}" />
      <QUERY objecttype="Situation" schemaversion="1.5" limit="50">
        <INCLUDE>Deviation.Message</INCLUDE>
        <INCLUDE>Deviation.IconId</INCLUDE>
        <INCLUDE>Deviation.Geometry.WGS84</INCLUDE>
        <INCLUDE>Deviation.SeverityText</INCLUDE>
        <INCLUDE>Deviation.StartTime</INCLUDE>
        <INCLUDE>Deviation.EndTime</INCLUDE>
        <INCLUDE>Deviation.LocationDescriptor</INCLUDE>
        <INCLUDE>Deviation.RoadNumber</INCLUDE>
      </QUERY>
    </REQUEST>
    """
    try:
        data = await _request(xml)
        results = data.get("RESPONSE", {}).get("RESULT", [])
        if not results:
            return []
        situations = results[0].get("Situation", [])
        parsed = []
        for sit in situations:
            deviations = sit.get("Deviation", [])
            if isinstance(deviations, dict):
                deviations = [deviations]
            for dev in deviations:
                geom = dev.get("Geometry", {}).get("WGS84")
                coords = _parse_wgs84_point(geom)
                # Filter by bbox if we have coordinates
                if coords and not _point_in_bbox(coords[0], coords[1], bbox):
                    continue
                # Skip situations with empty messages
                message = (dev.get("Message") or "").strip()
                if not message:
                    continue
                parsed.append({
                    "message": message,
                    "severity": dev.get("SeverityText", ""),
                    "location": dev.get("LocationDescriptor", ""),
                    "road": dev.get("RoadNumber", ""),
                    "start_time": dev.get("StartTime"),
                    "end_time": dev.get("EndTime"),
                    "lat": coords[0] if coords else None,
                    "lon": coords[1] if coords else None,
                })
        return parsed
    except Exception as e:
        print(f"TrafikverketClient: fetch_situations error: {e}")
        return []


async def fetch_road_condition(bbox: Dict[str, float]) -> List[Dict[str, Any]]:
    """Fetch road surface conditions within a bounding box."""
    box_val = _bbox_value(bbox)
    xml = f"""
    <REQUEST>
      <LOGIN authenticationkey="{API_KEY}" />
      <QUERY objecttype="RoadCondition" schemaversion="1.2" limit="20">
        <FILTER>
          <WITHIN name="Geometry.WGS84" shape="box" value="{box_val}" />
        </FILTER>
        <INCLUDE>ConditionText</INCLUDE>
        <INCLUDE>Geometry.WGS84</INCLUDE>
        <INCLUDE>RoadNumberNumeric</INCLUDE>
      </QUERY>
    </REQUEST>
    """
    try:
        data = await _request(xml)
        results = data.get("RESPONSE", {}).get("RESULT", [])
        if not results:
            return []
        conditions = results[0].get("RoadCondition", [])
        parsed = []
        for c in conditions:
            geom = c.get("Geometry", {}).get("WGS84")
            coords = _parse_wgs84_point(geom)
            parsed.append({
                "condition": c.get("ConditionText", ""),
                "road": c.get("RoadNumberNumeric"),
                "lat": coords[0] if coords else None,
                "lon": coords[1] if coords else None,
            })
        return parsed
    except Exception as e:
        print(f"TrafikverketClient: fetch_road_condition error: {e}")
        return []


async def fetch_measurement_sites(_bbox: Dict[str, float]) -> Dict[str, Dict[str, Any]]:
    """Fetch measurement site metadata - returns empty as Trafikverket
    TrafficFlow doesn't expose road numbers in the public API."""
    # Note: Trafikverket TrafficFlow identifies sites by SiteId but road info
    # isn't available. Smart filtering uses road names from OSRM route instead.
    _ = _bbox  # Unused, kept for API compatibility
    return {}


async def fetch_cameras(bbox: Dict[str, float]) -> List[Dict[str, Any]]:
    """Fetch traffic camera info within a bounding box."""
    box_val = _bbox_value(bbox)
    xml = f"""
    <REQUEST>
      <LOGIN authenticationkey="{API_KEY}" />
      <QUERY objecttype="Camera" schemaversion="1" limit="20">
        <FILTER>
          <WITHIN name="Geometry.WGS84" shape="box" value="{box_val}" />
        </FILTER>
        <INCLUDE>Name</INCLUDE>
        <INCLUDE>Geometry.WGS84</INCLUDE>
        <INCLUDE>PhotoUrl</INCLUDE>
        <INCLUDE>PhotoTime</INCLUDE>
        <INCLUDE>Description</INCLUDE>
      </QUERY>
    </REQUEST>
    """
    try:
        data = await _request(xml)
        results = data.get("RESPONSE", {}).get("RESULT", [])
        if not results:
            return []
        cameras = results[0].get("Camera", [])
        parsed = []
        for cam in cameras:
            geom = cam.get("Geometry", {}).get("WGS84")
            coords = _parse_wgs84_point(geom)
            parsed.append({
                "name": cam.get("Name", ""),
                "description": cam.get("Description", ""),
                "photo_url": cam.get("PhotoUrl"),
                "photo_time": cam.get("PhotoTime"),
                "lat": coords[0] if coords else None,
                "lon": coords[1] if coords else None,
            })
        return parsed
    except Exception as e:
        print(f"TrafikverketClient: fetch_cameras error: {e}")
        return []
