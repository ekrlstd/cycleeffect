"""
SLM Service - Generates traffic narrations.
Currently uses rule-based generation. Can be upgraded to use Qwen3 when disk space allows.
"""
from typing import List, Dict, Any

# Flag to indicate if real SLM is available
USE_REAL_SLM = False


def summarize_traffic_data(traffic_updates: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Summarize multiple traffic updates into a concise format.
    Takes the last update's state and aggregates key info.
    """
    if not traffic_updates:
        return {"error": "No traffic data"}
    
    # Use the last update for current state
    last_update = traffic_updates[-1]
    state = last_update.get("state", {})
    
    # Count object types
    objects = state.get("objects", [])
    type_counts = {}
    stopped_count = 0
    emergency_vehicles = []
    moving_vehicles = []
    
    for obj in objects:
        obj_type = obj.get("type", "unknown")
        type_counts[obj_type] = type_counts.get(obj_type, 0) + 1
        if obj.get("stopped", False):
            stopped_count += 1
        else:
            moving_vehicles.append(obj_type)
        if obj_type in ["ambulance", "police_car"]:
            emergency_vehicles.append(obj_type)
    
    return {
        "signal_state": state.get("signalState", "unknown"),
        "total_vehicles": len(objects),
        "congestion_level": state.get("congestionLevel", 0),
        "vehicle_types": type_counts,
        "stopped_vehicles": stopped_count,
        "moving_vehicles": len(moving_vehicles),
        "emergency_vehicles": emergency_vehicles,
        "updates_analyzed": len(traffic_updates)
    }


def _congestion_label(level: int) -> str:
    """Convert congestion level number to human-readable label."""
    if level <= 3:
        return "light"
    elif level <= 7:
        return "moderate"
    elif level <= 12:
        return "heavy"
    else:
        return "severe"


def _format_vehicle_summary(counts: Dict[str, int]) -> str:
    """Format vehicle counts into a readable summary."""
    if not counts:
        return "no vehicles"
    
    # Prioritize certain types
    priority_order = ["ambulance", "police_car", "bus", "car", "taxi", "motorbike", "bicycle"]
    
    mentioned = []
    for vtype in priority_order:
        if vtype in counts and counts[vtype] > 0:
            count = counts[vtype]
            if vtype == "ambulance":
                mentioned.append(f"{count} ambulance{'s' if count > 1 else ''}")
            elif vtype == "police_car":
                mentioned.append(f"{count} police car{'s' if count > 1 else ''}")
            elif count > 1:
                mentioned.append(f"{count} {vtype}s")
            else:
                mentioned.append(f"a {vtype}")
    
    # Return top 3 to keep it concise
    return ", ".join(mentioned[:3]) if mentioned else "several vehicles"


def generate_narration(traffic_updates: List[Dict[str, Any]], intersection_id: int = 0) -> str:
    """
    Generate a concise traffic narration from buffered traffic data.
    
    Args:
        traffic_updates: List of traffic update dictionaries collected over ~10 seconds
        intersection_id: The intersection being monitored (1-5)
        
    Returns:
        A concise narration string suitable for TTS
    """
    # Use real SLM if enabled and available
    if USE_REAL_SLM:
        return _generate_with_slm(traffic_updates)

    summary = summarize_traffic_data(traffic_updates)
    summary['intersection_id'] = intersection_id  # Add intersection context
    
    if "error" in summary:
        return "No traffic data available."
    
    # Build the narration
    parts = []
    
    # Signal state - be more descriptive based on intersection
    signal = summary.get('signal_state', 'unknown')
    intersection_id = summary.get('intersection_id', 0)
    
    # Intersection 1 only has E-W lanes
    if intersection_id == 1:
        parts.append("Traffic flowing on the single road.")
    elif signal == "NS_GREEN":
        parts.append("North-south traffic has the green light.")
    elif signal == "EW_GREEN":
        parts.append("East-west traffic has the green light.")
    
    # Congestion
    congestion = _congestion_label(summary.get('congestion_level', 0))
    total = summary.get('total_vehicles', 0)
    if total > 0:
        parts.append(f"Traffic is {congestion} with {total} vehicles.")
    else:
        parts.append("The intersection is currently clear.")
    
    # Emergency vehicles (high priority)
    emergency = summary.get('emergency_vehicles', [])
    if emergency:
        if "ambulance" in emergency:
            parts.append("Caution: ambulance approaching!")
        if "police_car" in emergency:
            parts.append("Police vehicle in the area.")
    
    # Stopped vehicles
    stopped = summary.get('stopped_vehicles', 0)
    if stopped > 3:
        parts.append(f"{stopped} vehicles are waiting at the light.")
    
    # Vehicle mix (if interesting)
    types = summary.get('vehicle_types', {})
    if types.get('bus', 0) > 0:
        parts.append(f"Watch for the bus.")
    
    return " ".join(parts) if parts else "Intersection status normal."


# Optional: Real SLM integration when disk space allows
def _generate_with_slm(traffic_updates: List[Dict[str, Any]]) -> str:
    """
    Generate narration using the real Qwen3 SLM model.
    Currently disabled due to disk space constraints.
    """
    return generate_narration(traffic_updates)
