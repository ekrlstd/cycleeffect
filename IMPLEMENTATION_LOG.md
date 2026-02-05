# Implementation Log - Map + Routing + Rerouting Enhancements

## Session Date: 2026-02-03

## What Was Implemented

### 1. Fixed Geocoding for Natural Language Queries
**Problem:** "find me the nearest Ica" sent the full sentence to the geocoder, failing to find results.

**Solution:**
- **`lib/widgets/voice_pill.dart`** (lines 133-139): Added patterns to strip:
  - "find me the/find me a/find the/find a/find"
  - "hitta/sök efter/sök" (Swedish)
  - "nearest/closest/närmaste/närmsta" qualifiers

- **`backend/route_service.py`** (lines 17-28): Added `_clean_query()` function as server-side defense-in-depth that strips the same patterns before calling Nominatim.

**Test:** Say "nearest Ica" or "find me the closest ICA" → should route to nearest ICA store.

---

### 2. Alternative Routes from OSRM
**Problem:** Only one route returned, no way to see alternatives.

**Solution:**
- **`backend/route_service.py`** (lines 32-58): Modified `get_route()` to:
  - Request `alternatives=2` from OSRM
  - Return a list of routes instead of single route

- **`backend/main.py`** (lines 79-141): Updated `/api/route` endpoint to:
  - Process multiple routes from OSRM
  - Return `alternatives: [...]` array with each route's geometry, distance, duration
  - Store each alternative route in `_routes` dict for later use

- **`lib/models/route_model.dart`** (lines 43-77): Added `AlternativeRoute` class with:
  - `routeId`, `geometry`, `distanceM`, `durationS`, `trafficSites`

- **`lib/providers/route_provider.dart`**: Added:
  - `_alternatives` list and getter
  - `switchToAlternative(routeId)` method to swap primary/alternative routes

- **`lib/widgets/map_card.dart`**: Added:
  - Gray polylines for alternative routes (rendered behind main route)
  - "X alt" chip button (top-right) to open alternatives selector
  - Bottom sheet with route options showing distance/duration

**Test:** Create a route → see gray alternative polylines → tap "X alt" chip → select alternative.

---

### 3. Map Tap-to-Set-Destination
**Problem:** No way to tap the map to set a destination.

**Solution:**
- **`backend/route_service.py`** (lines 60-73): Added `reverse_geocode(lat, lon)` function using Nominatim reverse geocoding.

- **`backend/main.py`** (lines 143-202): Added `POST /api/route/coords` endpoint that:
  - Takes `dest_lat`, `dest_lon` (and optional `origin_lat`, `origin_lon`)
  - Reverse geocodes for display name
  - Returns same structure as `/api/route` including alternatives

- **`lib/services/route_service.dart`** (lines 91-115): Added `createRouteFromCoords()` method.

- **`lib/providers/route_provider.dart`** (lines 60-78): Added `createRouteFromCoords()` that calls the service.

- **`lib/widgets/map_card.dart`**: Added:
  - `onTap` callback to `MapOptions` (only active when no route exists)
  - `_showDestinationConfirmation()` bottom sheet showing coordinates with Cancel/Route buttons

**Test:** With no active route, tap anywhere on map → see confirmation sheet → tap "Route here".

---

### 4. Auto-Reroute on Severe Incidents
**Problem:** No warning when incidents/congestion appear on active route.

**Solution:**
- **`backend/route_service.py`** (lines 127-148): Added `detect_severe_incidents()` function that:
  - Matches Swedish/English severity keywords (olycka, accident, blocked, closed, etc.)
  - Filters to incidents within 500m of route geometry

- **`backend/main.py`** (lines 204-237): Added `GET /api/route/{id}/reroute` endpoint that:
  - Checks for severe incidents on route
  - Fetches fresh alternative from OSRM if incidents found
  - Returns `{reroute_needed, incidents, alternative}`

- **`lib/models/route_model.dart`** (lines 79-95): Added `RerouteInfo` class.

- **`lib/services/route_service.dart`** (lines 117-127): Added `checkReroute(routeId)` method.

- **`lib/providers/route_provider.dart`**: Added:
  - `_pendingReroute` state and getter
  - Reroute check in `refreshTraffic()` (runs every 60s)
  - `acceptReroute()` and `dismissReroute()` methods

- **`lib/widgets/map_card.dart`** (lines 243-282): Added orange alert banner:
  - "Incident ahead — alternative available"
  - Accept button (switches route)
  - Dismiss X button

**Test:** `curl http://localhost:8000/api/route/{id}/reroute` → if incidents exist, returns alternative.

---

### 5. Web Platform Fixes
**Problem:** TTS and location errors on web platform.

**Solution:**
- **`lib/services/tts_service.dart`**:
  - Replaced `dart:io` Platform checks with `kIsWeb` from foundation
  - Wrapped engine detection in try-catch (not supported on web/iOS)
  - TTS now initializes gracefully on web

- **`lib/services/location_service.dart`**:
  - Added `kIsWeb` import
  - On web permission denial, falls back to default Gothenburg location
  - App remains functional without GPS on web

---

## Files Modified

| File | Changes |
|------|---------|
| `lib/widgets/voice_pill.dart` | Added natural language stripping patterns |
| `lib/widgets/map_card.dart` | onTap handler, alt polylines, alt selector, reroute banner |
| `lib/providers/route_provider.dart` | Alternatives state, reroute state, new methods |
| `lib/services/route_service.dart` | `createRouteFromCoords()`, `checkReroute()` |
| `lib/models/route_model.dart` | `AlternativeRoute`, `RerouteInfo` classes |
| `lib/services/tts_service.dart` | Web platform compatibility |
| `lib/services/location_service.dart` | Web platform fallback |
| `backend/route_service.py` | `_clean_query()`, `reverse_geocode()`, `detect_severe_incidents()`, multi-route support |
| `backend/main.py` | `/api/route/coords`, `/api/route/{id}/reroute`, alternatives in response |

---

## How to Test

1. **Start backend:**
   ```bash
   cd cycleeffect/backend
   python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Run Flutter app:**
   ```bash
   cd cycleeffect
   flutter run -d chrome  # or flutter run for mobile
   ```

3. **Test natural language:**
   - Say/type "nearest Ica" or "find me the closest grocery store"

4. **Test map tap:**
   - With no route, tap anywhere on map → see confirmation → create route

5. **Test alternatives:**
   - After route created, see gray alternative lines
   - Tap "X alt" chip → select different route

6. **Test reroute API:**
   ```bash
   curl http://localhost:8000/api/route/{route_id}/reroute \
     -H "X-API-Key: headsup-dev-key"
   ```

---

## What's Left / Future Work

1. **Tap alternative polyline directly** - Currently need to use the chip/sheet, could add polyline tap detection

2. **Real-time reroute push** - Currently polls every 60s, could use WebSocket for instant alerts

3. **Multiple destination waypoints** - Support for multi-stop routes

4. **Traffic-aware routing** - Pass traffic data to OSRM or use traffic-weighted alternatives

5. **Voice confirmation** - TTS announces "Incident ahead, rerouting" when auto-reroute triggers

6. **Offline map tiles** - Cache map tiles for areas with poor connectivity

7. **Dark map theme** - Match the app's dark UI theme

---

## Known Issues

- `flutter_map` shows info messages about `flutter_map_cancellable_tile_provider` - optional optimization for web
- TTS has limited support on web (depends on browser's Web Speech API)
- Location falls back to Gothenburg (57.7089, 11.9746) when GPS unavailable on web
