"""
Route service: geocoding via Nominatim, routing via OSRM.
Both are free and require no API keys.
Uses httpx for modern TLS support (LibreSSL 2.8.3 on macOS can't connect to some servers).
"""
import math
import re
import httpx
from typing import List, Dict, Any, Optional, Tuple


NOMINATIM_URL = "https://nominatim.openstreetmap.org"
OSRM_URL = "http://router.project-osrm.org"
USER_AGENT = "HeadsupApp/1.0"


def _clean_query(text: str) -> str:
    """Strip natural-language preambles and qualifiers from a geocoding query."""
    # Remove preamble phrases
    text = re.sub(
        r'^(find me the |find me a |find the |find a |find |'
        r'take me to |drive me to |navigate to |go to |route to |get me to |'
        r'directions to |head to |hitta |sök efter |sök |'
        r'ta mig till |kör mig till |navigera till |vägen till |åk till )',
        '', text, flags=re.IGNORECASE,
    ).strip()
    # Remove proximity qualifiers
    text = re.sub(r'\b(nearest|closest|närmaste|närmsta)\b', '', text, flags=re.IGNORECASE).strip()
    # Remove trailing punctuation
    text = re.sub(r'[.?!]+$', '', text).strip()
    return text or text


async def geocode(place_name: str, bias_lat: float = 57.7089, bias_lon: float = 11.9746) -> Optional[Dict[str, Any]]:
    """Geocode a place name to lat/lon using Nominatim.

    Two-pass search strategy biased toward Göteborg centrum:
    1. Bounded search (~30km radius) — returns results strictly within the area
    2. If nothing found, unbounded search with soft bias (~50km viewbox)

    From all candidates, picks the one closest to the bias point via haversine.
    This ensures "nearest ICA" returns the ICA closest to centrum, not a random global hit.
    """
    place_name = _clean_query(place_name)
    async with httpx.AsyncClient(verify=False, timeout=10) as client:
        # Pass 1: bounded search within ~30km of Göteborg centrum
        resp = await client.get(
            f"{NOMINATIM_URL}/search",
            params={
                "q": place_name,
                "format": "jsonv2",
                "limit": 10,
                "viewbox": f"{bias_lon - 0.3},{bias_lat + 0.2},{bias_lon + 0.3},{bias_lat - 0.2}",
                "bounded": 1,
            },
            headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        results = resp.json()

        # Pass 2: if bounded returned nothing, widen to ~50km with soft bias
        if not results:
            resp = await client.get(
                f"{NOMINATIM_URL}/search",
                params={
                    "q": place_name,
                    "format": "jsonv2",
                    "limit": 10,
                    "viewbox": f"{bias_lon - 0.5},{bias_lat + 0.3},{bias_lon + 0.5},{bias_lat - 0.3}",
                    "bounded": 0,
                },
                headers={"User-Agent": USER_AGENT},
            )
            resp.raise_for_status()
            results = resp.json()

        if not results:
            return None

        # Pick the result closest to the user's location
        best = None
        best_dist = float("inf")
        for r in results:
            rlat, rlon = float(r["lat"]), float(r["lon"])
            d = _haversine(bias_lat, bias_lon, rlat, rlon)
            if d < best_dist:
                best_dist = d
                best = r

        return {
            "lat": float(best["lat"]),
            "lon": float(best["lon"]),
            "display_name": best.get("display_name", place_name),
        }


async def get_route(
    origin_lat: float, origin_lon: float,
    dest_lat: float, dest_lon: float,
    alternatives: int = 2,
) -> Optional[List[Dict[str, Any]]]:
    """Get driving routes from OSRM. Returns a list of route alternatives with road names."""
    async with httpx.AsyncClient(verify=False, timeout=10) as client:
        params = {
            "overview": "full",
            "geometries": "geojson",
            "steps": "true",  # Enable steps to get road names
        }
        if alternatives > 0:
            params["alternatives"] = str(alternatives)
        resp = await client.get(
            f"{OSRM_URL}/route/v1/driving/{origin_lon},{origin_lat};{dest_lon},{dest_lat}",
            params=params,
        )
        resp.raise_for_status()
        data = resp.json()
        if data.get("code") != "Ok" or not data.get("routes"):
            return None
        results = []
        for route in data["routes"]:
            coords = route["geometry"]["coordinates"]  # [[lon, lat], ...]

            # Extract road names and refs from steps
            road_names = set()
            road_refs = set()  # Highway numbers like E6, E45, 40
            for leg in route.get("legs", []):
                for step in leg.get("steps", []):
                    name = step.get("name", "").strip()
                    ref = step.get("ref", "").strip()
                    if name:
                        road_names.add(name.lower())
                    if ref:
                        # Handle multiple refs like "E6;E45"
                        for r in ref.split(";"):
                            road_refs.add(r.strip().upper())

            results.append({
                "geometry": coords,
                "distance_m": route["distance"],
                "duration_s": route["duration"],
                "road_names": list(road_names),
                "road_refs": list(road_refs),
            })
        return results


async def reverse_geocode(lat: float, lon: float) -> Optional[Dict[str, Any]]:
    """Reverse geocode coordinates to an address using Nominatim."""
    async with httpx.AsyncClient(verify=False, timeout=10) as client:
        resp = await client.get(
            f"{NOMINATIM_URL}/reverse",
            params={"lat": lat, "lon": lon, "format": "jsonv2"},
            headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        data = resp.json()
        if "error" in data:
            return None
        return {
            "lat": float(data["lat"]),
            "lon": float(data["lon"]),
            "display_name": data.get("display_name", f"{lat:.4f}, {lon:.4f}"),
        }


def get_route_bbox(geometry: List[List[float]], padding_m: float = 500.0) -> Dict[str, float]:
    """Compute a bounding box around a route geometry with padding."""
    lats = [c[1] for c in geometry]
    lons = [c[0] for c in geometry]
    min_lat, max_lat = min(lats), max(lats)
    min_lon, max_lon = min(lons), max(lons)
    lat_pad = padding_m / 111_000
    lon_pad = padding_m / (111_000 * math.cos(math.radians((min_lat + max_lat) / 2)))
    return {
        "min_lat": min_lat - lat_pad,
        "max_lat": max_lat + lat_pad,
        "min_lon": min_lon - lon_pad,
        "max_lon": max_lon + lon_pad,
    }


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6_371_000
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    return 2 * R * math.asin(math.sqrt(a))


def match_sites_to_route(
    sites: List[Dict[str, Any]],
    geometry: List[List[float]],
    radius_m: float = 2500.0,
) -> List[Dict[str, Any]]:
    """Filter traffic flow sites to only those near the route."""
    matched = []
    for site in sites:
        slat, slon = site.get("lat"), site.get("lon")
        if slat is None or slon is None:
            continue
        for coord in geometry:
            if _haversine(slat, slon, coord[1], coord[0]) <= radius_m:
                matched.append(site)
                break
    return matched


def match_sites_by_road(
    sites: List[Dict[str, Any]],
    site_metadata: Dict[str, Dict[str, Any]],
    route_road_refs: List[str],
    geometry: List[List[float]],
    fallback_radius_m: float = 500.0,
) -> List[Dict[str, Any]]:
    """
    Smart filter: only include sites on roads the user is traveling on.

    Args:
        sites: Traffic flow data with site_id
        site_metadata: Mapping of site_id -> {road_number, name}
        route_road_refs: List of road numbers from the route (e.g., ['E6', '40', 'E45'])
        geometry: Route geometry for fallback distance matching
        fallback_radius_m: If no road match, include if very close to route

    Returns:
        Filtered list of sites on matching roads
    """
    if not route_road_refs:
        # No road refs from route, fall back to distance matching
        print("match_sites_by_road: No road refs, using distance fallback")
        return match_sites_to_route(sites, geometry, fallback_radius_m)

    # Normalize route road refs for comparison
    normalized_refs = set()
    for ref in route_road_refs:
        # Handle formats: "E6", "E 6", "Route 40", "40", "E6;E45"
        ref_clean = ref.upper().replace(" ", "")
        normalized_refs.add(ref_clean)
        # Also add without prefix letters for numeric roads
        import re as regex
        num_match = regex.search(r'\d+', ref)
        if num_match:
            normalized_refs.add(num_match.group())

    print(f"match_sites_by_road: Looking for roads: {normalized_refs}")

    matched = []
    matched_by_road = 0
    matched_by_distance = 0

    for site in sites:
        site_id = site.get("site_id")
        slat, slon = site.get("lat"), site.get("lon")

        # Try road-based matching first
        if site_id and str(site_id) in site_metadata:
            meta = site_metadata[str(site_id)]
            road_num = meta.get("road_number")
            if road_num:
                road_str = str(road_num).upper().replace(" ", "")
                # Check if this road matches any route road
                if road_str in normalized_refs:
                    site["_matched_road"] = road_num
                    matched.append(site)
                    matched_by_road += 1
                    continue
                # Also check numeric part
                num_match = regex.search(r'\d+', road_str)
                if num_match and num_match.group() in normalized_refs:
                    site["_matched_road"] = road_num
                    matched.append(site)
                    matched_by_road += 1
                    continue

        # Fallback: include if very close to the route (within tight radius)
        if slat is not None and slon is not None:
            for coord in geometry:
                if _haversine(slat, slon, coord[1], coord[0]) <= fallback_radius_m:
                    site["_matched_proximity"] = True
                    matched.append(site)
                    matched_by_distance += 1
                    break

    print(f"match_sites_by_road: Matched {matched_by_road} by road, {matched_by_distance} by proximity")
    return matched


def detect_severe_incidents(
    situations: List[Dict[str, Any]],
    geometry: List[List[float]],
    radius_m: float = 500.0,
) -> List[Dict[str, Any]]:
    """Find severe incidents near the route."""
    severe_keywords = re.compile(
        r'(olycka|accident|blockerad|blocked|avstängd|closed|stopp|'
        r'road.?closed|major|severe|critical|trafikolycka|väg.?avstängd)',
        re.IGNORECASE,
    )
    severe = []
    for sit in situations:
        slat, slon = sit.get("lat"), sit.get("lon")
        text = f"{sit.get('message', '')} {sit.get('severity', '')}"
        if not severe_keywords.search(text):
            continue
        if slat is not None and slon is not None:
            near = any(
                _haversine(slat, slon, c[1], c[0]) <= radius_m
                for c in geometry
            )
            if not near:
                continue
        severe.append(sit)
    return severe


def point_along_route_description(
    lat: float, lon: float, geometry: List[List[float]]
) -> str:
    """Describe where a point is relative to the route."""
    if not geometry:
        return "along the route"
    total_points = len(geometry)
    best_idx = 0
    best_dist = float("inf")
    for i, coord in enumerate(geometry):
        d = _haversine(lat, lon, coord[1], coord[0])
        if d < best_dist:
            best_dist = d
            best_idx = i
    frac = best_idx / max(total_points - 1, 1)
    if frac < 0.25:
        return "near the start of your route"
    elif frac < 0.75:
        return "along the middle of your route"
    else:
        return "near your destination"
