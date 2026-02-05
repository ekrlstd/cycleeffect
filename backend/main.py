from fastapi import FastAPI, Header, HTTPException, Query
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from sse_starlette.sse import EventSourceResponse
from pydantic import BaseModel
import asyncio
import json
import os
import uuid
from typing import Optional

import trafikverket_client as tv
import route_service
import cache
from slm_service import generate_narration_from_real_data, generate_voice_response

API_KEY = os.environ.get("HEADSUP_API_KEY", "headsup-dev-key")
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "*").split(",")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)


def verify_api_key(x_api_key: str = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")


# Store route metadata (geometry, destination, bbox) separately from cache
_routes: dict = {}


@app.on_event("startup")
async def startup_event():
    # Periodic cleanup of stale cache entries
    async def _cleanup_loop():
        while True:
            await asyncio.sleep(300)
            cache.cleanup_stale()
    asyncio.create_task(_cleanup_loop())


@app.get("/")
async def root():
    index_path = os.path.join(os.path.dirname(__file__), "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"status": "ok", "message": "Headsup API — real traffic data"}


# ============= ROUTE ENDPOINTS =============

class RouteRequest(BaseModel):
    destination_name: str
    origin_lat: Optional[float] = None
    origin_lon: Optional[float] = None


@app.post("/api/route")
async def create_route(req: RouteRequest, x_api_key: str = Header(None)):
    """Create a route: geocode destination, compute route, fetch real traffic."""
    verify_api_key(x_api_key)

    # Geocode destination
    dest = await route_service.geocode(req.destination_name)
    if dest is None:
        raise HTTPException(status_code=404, detail=f"Could not find '{req.destination_name}'")

    # Origin: use provided or default to central Gothenburg
    origin_lat = req.origin_lat or 57.7089
    origin_lon = req.origin_lon or 11.9746

    # Get routes (with alternatives)
    routes = await route_service.get_route(origin_lat, origin_lon, dest["lat"], dest["lon"])
    if routes is None or len(routes) == 0:
        raise HTTPException(status_code=502, detail="Could not compute route")

    primary = routes[0]
    geometry = primary["geometry"]  # [[lon, lat], ...]
    bbox = route_service.get_route_bbox(geometry)

    # Fetch real traffic data
    traffic_flow, situations, road_condition = await asyncio.gather(
        tv.fetch_traffic_flow(bbox),
        tv.fetch_situations(bbox),
        tv.fetch_road_condition(bbox),
    )

    # Filter traffic sites to those near the route
    matched_flow = route_service.match_sites_to_route(traffic_flow, geometry)

    route_id = str(uuid.uuid4())[:8]

    # Build alternative route entries
    alt_routes = []
    for i, alt in enumerate(routes[1:], start=1):
        alt_id = f"{route_id}-alt{i}"
        alt_bbox = route_service.get_route_bbox(alt["geometry"])
        alt_matched = route_service.match_sites_to_route(traffic_flow, alt["geometry"])
        alt_routes.append({
            "route_id": alt_id,
            "geometry": alt["geometry"],
            "distance_m": alt["distance_m"],
            "duration_s": alt["duration_s"],
            "traffic_sites": alt_matched,
        })
        _routes[alt_id] = {
            "geometry": alt["geometry"],
            "bbox": alt_bbox,
            "destination": dest,
            "distance_m": alt["distance_m"],
            "duration_s": alt["duration_s"],
        }

    # Store route info
    _routes[route_id] = {
        "geometry": geometry,
        "bbox": bbox,
        "destination": dest,
        "distance_m": primary["distance_m"],
        "duration_s": primary["duration_s"],
    }

    # Cache traffic data
    cache.put(route_id, {
        "traffic_flow": matched_flow,
        "situations": situations,
        "road_condition": road_condition,
    }, bbox, geometry)

    # Start background refresh
    async def _refresh(rid):
        info = _routes.get(rid)
        if not info:
            return
        tf, si, rc = await asyncio.gather(
            tv.fetch_traffic_flow(info["bbox"]),
            tv.fetch_situations(info["bbox"]),
            tv.fetch_road_condition(info["bbox"]),
        )
        matched = route_service.match_sites_to_route(tf, info["geometry"])
        cache.put(rid, {"traffic_flow": matched, "situations": si, "road_condition": rc},
                  info["bbox"], info["geometry"])

    cache.start_refresh(route_id, _refresh)

    return {
        "route_id": route_id,
        "destination": dest,
        "geometry": geometry,
        "distance_m": primary["distance_m"],
        "duration_s": primary["duration_s"],
        "traffic_sites": matched_flow,
        "situations": situations,
        "road_condition": road_condition,
        "alternatives": alt_routes,
    }


class CoordsRouteRequest(BaseModel):
    dest_lat: float
    dest_lon: float
    origin_lat: Optional[float] = None
    origin_lon: Optional[float] = None


@app.post("/api/route/coords")
async def create_route_from_coords(req: CoordsRouteRequest, x_api_key: str = Header(None)):
    """Create a route from coordinates (skip geocoding)."""
    verify_api_key(x_api_key)

    # Reverse geocode for display name
    dest = await route_service.reverse_geocode(req.dest_lat, req.dest_lon)
    if dest is None:
        dest = {"lat": req.dest_lat, "lon": req.dest_lon, "display_name": f"{req.dest_lat:.4f}, {req.dest_lon:.4f}"}

    origin_lat = req.origin_lat or 57.7089
    origin_lon = req.origin_lon or 11.9746

    routes = await route_service.get_route(origin_lat, origin_lon, req.dest_lat, req.dest_lon)
    if routes is None or len(routes) == 0:
        raise HTTPException(status_code=502, detail="Could not compute route")

    primary = routes[0]
    geometry = primary["geometry"]
    bbox = route_service.get_route_bbox(geometry)

    traffic_flow, situations, road_condition = await asyncio.gather(
        tv.fetch_traffic_flow(bbox),
        tv.fetch_situations(bbox),
        tv.fetch_road_condition(bbox),
    )
    matched_flow = route_service.match_sites_to_route(traffic_flow, geometry)

    route_id = str(uuid.uuid4())[:8]

    alt_routes = []
    for i, alt in enumerate(routes[1:], start=1):
        alt_id = f"{route_id}-alt{i}"
        alt_bbox = route_service.get_route_bbox(alt["geometry"])
        alt_matched = route_service.match_sites_to_route(traffic_flow, alt["geometry"])
        alt_routes.append({
            "route_id": alt_id,
            "geometry": alt["geometry"],
            "distance_m": alt["distance_m"],
            "duration_s": alt["duration_s"],
            "traffic_sites": alt_matched,
        })
        _routes[alt_id] = {
            "geometry": alt["geometry"], "bbox": alt_bbox,
            "destination": dest, "distance_m": alt["distance_m"], "duration_s": alt["duration_s"],
        }

    _routes[route_id] = {
        "geometry": geometry, "bbox": bbox, "destination": dest,
        "distance_m": primary["distance_m"], "duration_s": primary["duration_s"],
    }
    cache.put(route_id, {"traffic_flow": matched_flow, "situations": situations, "road_condition": road_condition}, bbox, geometry)

    async def _refresh(rid):
        info = _routes.get(rid)
        if not info:
            return
        tf, si, rc = await asyncio.gather(
            tv.fetch_traffic_flow(info["bbox"]), tv.fetch_situations(info["bbox"]), tv.fetch_road_condition(info["bbox"]),
        )
        matched = route_service.match_sites_to_route(tf, info["geometry"])
        cache.put(rid, {"traffic_flow": matched, "situations": si, "road_condition": rc}, info["bbox"], info["geometry"])

    cache.start_refresh(route_id, _refresh)

    return {
        "route_id": route_id, "destination": dest, "geometry": geometry,
        "distance_m": primary["distance_m"], "duration_s": primary["duration_s"],
        "traffic_sites": matched_flow, "situations": situations, "road_condition": road_condition,
        "alternatives": alt_routes,
    }


@app.get("/api/route/{route_id}/traffic")
async def get_route_traffic(route_id: str, x_api_key: str = Header(None)):
    """Get cached real traffic data for a route."""
    verify_api_key(x_api_key)

    data = cache.get(route_id)
    if data is None:
        # Try refreshing
        info = _routes.get(route_id)
        if info is None:
            raise HTTPException(status_code=404, detail="Route not found")
        tf, si, rc = await asyncio.gather(
            tv.fetch_traffic_flow(info["bbox"]),
            tv.fetch_situations(info["bbox"]),
            tv.fetch_road_condition(info["bbox"]),
        )
        matched = route_service.match_sites_to_route(tf, info["geometry"])
        data = {"traffic_flow": matched, "situations": si, "road_condition": rc}
        cache.put(route_id, data, info["bbox"], info["geometry"])

    return data


@app.get("/api/route/{route_id}/narration")
async def narration_stream(
    route_id: str,
    lat: float = Query(57.7089),
    lon: float = Query(11.9746),
    x_api_key: str = Header(None),
):
    """SSE endpoint: stream narration every 30s from real data near user position."""
    verify_api_key(x_api_key)

    info = _routes.get(route_id)
    if info is None:
        raise HTTPException(status_code=404, detail="Route not found")

    async def _generate():
        while True:
            data = cache.get(route_id)
            if data is None:
                yield {"event": "narration", "data": json.dumps({"text": "Updating traffic data..."})}
                await asyncio.sleep(10)
                continue

            segment_desc = route_service.point_along_route_description(
                lat, lon, info["geometry"]
            )
            narration = generate_narration_from_real_data(
                data.get("traffic_flow", []),
                data.get("situations", []),
                data.get("road_condition", []),
                segment_desc,
            )
            yield {
                "event": "narration",
                "data": json.dumps({
                    "text": narration,
                    "route_id": route_id,
                })
            }
            await asyncio.sleep(30)

    return EventSourceResponse(_generate())


@app.get("/api/route/{route_id}/reroute")
async def check_reroute(route_id: str, x_api_key: str = Header(None)):
    """Check if severe incidents warrant a reroute and return alternative if so."""
    verify_api_key(x_api_key)

    info = _routes.get(route_id)
    if info is None:
        raise HTTPException(status_code=404, detail="Route not found")

    data = cache.get(route_id)
    situations = data.get("situations", []) if data else []

    severe = route_service.detect_severe_incidents(situations, info["geometry"])
    if not severe:
        return {"reroute_needed": False}

    # Get a fresh alternative route
    dest = info["destination"]
    geometry = info["geometry"]
    origin = geometry[0]  # [lon, lat]
    routes = await route_service.get_route(origin[1], origin[0], dest["lat"], dest["lon"])
    if routes is None or len(routes) < 2:
        return {"reroute_needed": True, "incidents": severe, "alternative": None}

    alt = routes[1]
    alt_id = str(uuid.uuid4())[:8]
    alt_bbox = route_service.get_route_bbox(alt["geometry"])
    _routes[alt_id] = {
        "geometry": alt["geometry"], "bbox": alt_bbox, "destination": dest,
        "distance_m": alt["distance_m"], "duration_s": alt["duration_s"],
    }
    return {
        "reroute_needed": True,
        "incidents": severe,
        "alternative": {
            "route_id": alt_id,
            "geometry": alt["geometry"],
            "distance_m": alt["distance_m"],
            "duration_s": alt["duration_s"],
        },
    }


# ============= VOICE ENDPOINT =============

class VoiceRequest(BaseModel):
    text: str
    route_id: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None


@app.post("/api/voice")
async def voice_query(req: VoiceRequest, x_api_key: str = Header(None)):
    """Handle voice query with real traffic context."""
    verify_api_key(x_api_key)

    traffic_flow = []
    situations = []
    road_condition = []

    if req.route_id:
        data = cache.get(req.route_id)
        if data:
            traffic_flow = data.get("traffic_flow", [])
            situations = data.get("situations", [])
            road_condition = data.get("road_condition", [])

    response = generate_voice_response(req.text, traffic_flow, situations, road_condition)
    return {"response": response}


# ============= GEOCODE PROXY =============

@app.get("/api/geocode")
async def geocode_proxy(q: str = Query(...), x_api_key: str = Header(None)):
    """Proxy Nominatim geocoding."""
    verify_api_key(x_api_key)
    result = await route_service.geocode(q)
    if result is None:
        raise HTTPException(status_code=404, detail=f"Could not find '{q}'")
    return result
