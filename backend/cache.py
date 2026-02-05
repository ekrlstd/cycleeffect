"""
In-memory cache for route traffic data with TTL-based expiration.
"""
import asyncio
import time
from typing import Dict, Any, Optional

# route_id -> {data, timestamp, bbox, geometry}
_cache: Dict[str, Dict[str, Any]] = {}
_TTL = 60  # seconds
_refresh_tasks: Dict[str, asyncio.Task] = {}


def get(route_id: str) -> Optional[Dict[str, Any]]:
    """Get cached data for a route if still fresh."""
    entry = _cache.get(route_id)
    if entry is None:
        return None
    if time.time() - entry["timestamp"] > _TTL:
        return None
    return entry["data"]


def put(route_id: str, data: Dict[str, Any], bbox: Dict[str, float], geometry: list):
    """Store data for a route."""
    _cache[route_id] = {
        "data": data,
        "timestamp": time.time(),
        "bbox": bbox,
        "geometry": geometry,
    }


def get_route_info(route_id: str) -> Optional[Dict[str, Any]]:
    """Get the bbox and geometry for a cached route."""
    entry = _cache.get(route_id)
    if entry is None:
        return None
    return {"bbox": entry["bbox"], "geometry": entry["geometry"]}


def start_refresh(route_id: str, refresh_fn):
    """Start a background refresh task for a route."""
    if route_id in _refresh_tasks:
        return  # Already running

    async def _loop():
        while route_id in _cache:
            await asyncio.sleep(_TTL)
            if route_id not in _cache:
                break
            try:
                await refresh_fn(route_id)
            except Exception as e:
                print(f"Cache refresh error for {route_id}: {e}")

    _refresh_tasks[route_id] = asyncio.create_task(_loop())


def remove(route_id: str):
    """Remove a route from cache and stop its refresh."""
    _cache.pop(route_id, None)
    task = _refresh_tasks.pop(route_id, None)
    if task:
        task.cancel()


def cleanup_stale(max_age: float = 600):
    """Remove routes not refreshed in max_age seconds."""
    now = time.time()
    stale = [rid for rid, entry in _cache.items() if now - entry["timestamp"] > max_age]
    for rid in stale:
        remove(rid)
