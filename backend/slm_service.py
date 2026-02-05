"""
SLM Service - Generates traffic narrations from real Trafikverket data.
Rule-based for MVP. Can be upgraded to Qwen3 later.
"""
from typing import List, Dict, Any

# Swedish → English condition translations
_SWEDISH_CONDITIONS = {
    "besvärligt": "difficult conditions",
    "halt väglag": "slippery road",
    "is": "icy",
    "snö": "snow",
    "regn": "rain",
    "dimma": "fog",
    "risk för halka": "risk of slippery conditions",
    "våt väg": "wet road",
    "torr väg": "dry road",
    "god sikt": "good visibility",
    "dålig sikt": "poor visibility",
}


def _translate_condition(text: str) -> str:
    """Translate common Swedish road condition terms to English."""
    lower = text.lower()
    for sv, en in _SWEDISH_CONDITIONS.items():
        if sv in lower:
            return en
    return text


def _summarize_traffic(traffic_flow: List[Dict[str, Any]]) -> str:
    """Summarize traffic flow data into a sentence."""
    if not traffic_flow:
        return ""
    speeds = [f["speed"] for f in traffic_flow if f.get("speed") is not None]
    if not speeds:
        return ""
    avg_speed = sum(speeds) / len(speeds)
    if avg_speed < 20:
        return f"Traffic is very slow, averaging {int(avg_speed)} km/h."
    elif avg_speed < 50:
        return f"Traffic is moving slowly at about {int(avg_speed)} km/h."
    elif avg_speed < 80:
        return f"Traffic is flowing normally at {int(avg_speed)} km/h."
    else:
        return f"Traffic is moving freely at {int(avg_speed)} km/h."


def _summarize_situations(situations: List[Dict[str, Any]]) -> str:
    """Summarize incidents into a sentence."""
    active = [s for s in situations if s.get("message", "").strip()]
    if not active:
        return "No incidents reported."
    count = len(active)
    sample = active[0]["message"][:100]
    if count == 1:
        return f"One incident: {sample}."
    return f"{count} incidents reported. Most recent: {sample}."


def _summarize_conditions(road_condition: List[Dict[str, Any]]) -> str:
    """Summarize road conditions."""
    conds = set()
    for rc in road_condition:
        c = rc.get("condition", "").strip()
        if c:
            conds.add(_translate_condition(c))
    if not conds:
        return ""
    return "Road conditions: " + "; ".join(list(conds)[:3]) + "."


def generate_narration_from_real_data(
    traffic_flow: List[Dict[str, Any]],
    situations: List[Dict[str, Any]],
    road_condition: List[Dict[str, Any]],
    segment_description: str = "along your route",
) -> str:
    """Generate a concise voice narration from real traffic data."""
    parts = []

    if traffic_flow:
        speeds = [f["speed"] for f in traffic_flow if f.get("speed") is not None]
        flows = [f["flow_rate"] for f in traffic_flow if f.get("flow_rate") is not None]

        if speeds:
            avg_speed = sum(speeds) / len(speeds)
            if avg_speed < 20:
                parts.append(f"Traffic is very slow {segment_description}, averaging {int(avg_speed)} km/h.")
            elif avg_speed < 50:
                parts.append(f"Traffic is moving slowly {segment_description} at about {int(avg_speed)} km/h.")
            elif avg_speed < 80:
                parts.append(f"Traffic is flowing normally {segment_description} at {int(avg_speed)} km/h.")
            else:
                parts.append(f"Traffic is moving freely {segment_description} at {int(avg_speed)} km/h.")

        if flows:
            total_flow = sum(flows)
            if total_flow > 100:
                parts.append(f"Heavy volume with {total_flow} vehicles per hour.")
            elif total_flow > 40:
                parts.append("Moderate traffic volume.")
    else:
        parts.append(f"No traffic sensor data available {segment_description}.")

    # Only include situations with non-empty messages
    valid_situations = [s for s in situations if s.get("message", "").strip()]
    if valid_situations:
        for sit in valid_situations[:2]:
            msg = sit["message"]
            severity = sit.get("severity", "")
            road = sit.get("road", "")
            prefix = ""
            if "olycka" in msg.lower() or "accident" in msg.lower():
                prefix = "Warning: "
            elif severity and "allvarlig" in severity.lower():
                prefix = "Caution: "
            location_info = f" on road {road}" if road else ""
            short_msg = msg[:120] + "..." if len(msg) > 120 else msg
            parts.append(f"{prefix}{short_msg}{location_info}.")

    if road_condition:
        conditions = set()
        for rc in road_condition:
            cond = rc.get("condition", "").strip()
            if cond:
                conditions.add(_translate_condition(cond))
        if conditions:
            cond_str = "; ".join(list(conditions)[:2])
            parts.append(f"Road conditions: {cond_str}.")

    if not parts:
        return "Route conditions are normal. Drive safely."

    return " ".join(parts)


def generate_voice_response(
    query: str,
    traffic_flow: List[Dict[str, Any]],
    situations: List[Dict[str, Any]],
    road_condition: List[Dict[str, Any]],
) -> str:
    """Generate a response to a voice query using real data context."""
    query_lower = query.lower()

    # Speed / traffic queries
    if any(w in query_lower for w in ["speed", "fast", "slow", "traffic", "congestion", "busy", "crowded"]):
        if traffic_flow:
            speeds = [f["speed"] for f in traffic_flow if f.get("speed") is not None]
            if speeds:
                avg = sum(speeds) / len(speeds)
                mn, mx = min(speeds), max(speeds)
                return (
                    f"Current traffic speed ranges from {int(mn)} to {int(mx)} km/h, "
                    f"averaging {int(avg)} km/h along your route."
                )
        return "I don't have speed data for your route right now."

    # Accident / incident queries
    if any(w in query_lower for w in ["accident", "incident", "crash", "blocked", "closure", "problem"]):
        valid = [s for s in situations if s.get("message", "").strip()]
        if valid:
            msgs = [s["message"][:100] for s in valid[:3]]
            return "Current incidents along your route: " + " | ".join(msgs)
        return "No incidents reported along your route."

    # Road condition queries
    if any(w in query_lower for w in ["road", "condition", "surface", "ice", "wet", "slippery", "snow"]):
        if road_condition:
            conds = [_translate_condition(rc.get("condition", "")) for rc in road_condition if rc.get("condition", "").strip()]
            if conds:
                return "Road conditions: " + "; ".join(conds[:3])
        return "No specific road condition reports for your route."

    # Safety queries
    if any(w in query_lower for w in ["safe", "danger", "risk", "careful", "warning"]):
        parts = []
        valid_sits = [s for s in situations if s.get("message", "").strip()]
        if valid_sits:
            parts.append(f"{len(valid_sits)} incident(s) reported nearby.")
        else:
            parts.append("No incidents reported.")
        cond_summary = _summarize_conditions(road_condition)
        if cond_summary:
            parts.append(cond_summary)
        traffic_summary = _summarize_traffic(traffic_flow)
        if traffic_summary:
            parts.append(traffic_summary)
        if not parts:
            return "Conditions look safe. Drive carefully."
        return " ".join(parts)

    # Time / ETA queries
    if any(w in query_lower for w in ["time", "eta", "long", "arrive", "when", "how far", "minutes"]):
        if traffic_flow:
            speeds = [f["speed"] for f in traffic_flow if f.get("speed") is not None]
            if speeds:
                avg = sum(speeds) / len(speeds)
                if avg < 30:
                    return f"Traffic is slow at {int(avg)} km/h. Expect delays on your route."
                return f"Traffic is flowing at {int(avg)} km/h. No major delays expected."
        return "I don't have enough data to estimate travel time right now."

    # Weather queries
    if any(w in query_lower for w in ["weather", "rain", "fog", "visibility", "wind"]):
        cond_summary = _summarize_conditions(road_condition)
        if cond_summary:
            return cond_summary
        return "No weather-related road condition data available right now."

    # General "how is it" / overview queries
    if any(w in query_lower for w in ["how", "what", "update", "status", "overview", "tell me", "anything"]):
        parts = []
        traffic_summary = _summarize_traffic(traffic_flow)
        if traffic_summary:
            parts.append(traffic_summary)
        sit_summary = _summarize_situations(situations)
        if sit_summary:
            parts.append(sit_summary)
        cond_summary = _summarize_conditions(road_condition)
        if cond_summary:
            parts.append(cond_summary)
        if parts:
            return " ".join(parts)
        return "Everything looks clear on your route. Drive safely."

    # Fallback: give a useful summary instead of raw dump
    parts = []
    traffic_summary = _summarize_traffic(traffic_flow)
    if traffic_summary:
        parts.append(traffic_summary)
    sit_summary = _summarize_situations(situations)
    if sit_summary:
        parts.append(sit_summary)
    cond_summary = _summarize_conditions(road_condition)
    if cond_summary:
        parts.append(cond_summary)
    if parts:
        return " ".join(parts)
    return "No traffic data available for your route right now."
