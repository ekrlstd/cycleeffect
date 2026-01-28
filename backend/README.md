# Backend Traffic Simulation Service

This service provides real-time, synthetic traffic data for multiple intersections via WebSocket endpoints. It simulates vehicle movements, traffic light cycles, and various object types.

## 🚀 Quick Start

1.  **Install Dependencies** (if not already installed):
    ```bash
    pip install "fastapi[standard]" uvicorn websockets
    ```

2.  **Run the Server**:
    ```bash
    ./venv/bin/uvicorn main:app --reload
    ```

3.  **Access the Visualization**:
    Open your browser to: [http://localhost:8000/visual](http://localhost:8000/visual)

## 📡 API Endpoints

### WebSockets (Traffic Data)

Connect to these endpoints to receive real-time JSON updates (10 updates/second).

*   `ws://localhost:8000/ws/traffic/1` - **Intersection 1** (Custom Single Road E-W)
*   `ws://localhost:8000/ws/traffic/2` - **Intersection 2**
*   `ws://localhost:8000/ws/traffic/3` - **Intersection 3**
*   `ws://localhost:8000/ws/traffic/4` - **Intersection 4**
*   `ws://localhost:8000/ws/traffic/5` - **Intersection 5**

### HTTP (Dashboards)

*   `GET /` - Single intersection debugger.
*   `GET /visual` - **Traffic Control Center** (Visualizes all 5 intersections).

---

## 💾 Data Dictionary

The WebSocket stream sends a JSON object 10 times per second.

### Root Object
| Field | Type | Description |
| :--- | :--- | :--- |
| `type` | String | Message type (e.g., `"update"`). |
| `timestamp` | Integer | Current server time (ms epoch). |
| `events` | Array | List of object "detections" (see below). |
| `state` | Object | Full state of the intersection. |

### Event Object (Inside `events` array)
Each item represents a physical object (vehicle) detected in the intersection.

| Field | Type | Description |
| :--- | :--- | :--- |
| `type` | String | Event type (always `"detection"`). |
| `objectType` | String | Class of the object. <br>Values: `car`, `taxi`, `bus`, `bicycle`, `motorbike`, `police_car`, `ambulance`. |
| `objectId` | String | Unique UUID for the vehicle (e.g., `obj_1a2b3c4d`). Persists as long as the object is in frame. |
| `x` | Float | **Horizontal Position** (0.0 to 1.0). <br>`0.0` = Left edge, `1.0` = Right edge. |
| `y` | Float | **Vertical Position** (0.0 to 1.0). <br>`0.0` = Bottom edge, `1.0` = Top edge. *(Note: Coordinate system may vary by simulation logic, see below)*. |
| `vx` | Float | **X Velocity**. Positive = Moving Right. Negative = Moving Left. |
| `vy` | Float | **Y Velocity**. Positive = Moving Up. Negative = Moving Down. |
| `heading` | Integer | Direction of travel in degrees (0-360).<br>`0`=North, `90`=East, `180`=South, `270`=West. |
| `lane` | String | Lane identifier (e.g., `N1`=Northbound Lane 1, `E1`=Eastbound Lane 1). |
| `confidence` | Float | Simulated detection confidence (0.0 - 1.0). |

### State Object (Inside `state` object)
Global metadata for the intersection.

| Field | Type | Description |
| :--- | :--- | :--- |
| `signalState` | String | Traffic light phase. <br>`NS_GREEN` = North/South Green.<br>`EW_GREEN` = East/West Green. |
| `congestionLevel`| Integer | Total count of objects currently in the intersection. |
| `objects` | Array | Same list as `events` (redundant full state snapshot). |

---

## ⚙️ How It Works

### Simulation Logic (`simulation.py`)
The system runs 5 independent `TrafficSimulator` instances in the background.

1.  **Coordinate System**: A 1.0 x 1.0 unit square.
    *   **N1 Lane** (Northbound): Spawns at `y=1.0`, moves with `vy < 0` (Down).
    *   **S1 Lane** (Southbound): Spawns at `y=0.0`, moves with `vy > 0` (Up).
    *   **E1 Lane** (Eastbound): Spawns at `x=0.0`, moves with `vx > 0` (Right).
    *   **W1 Lane** (Westbound): Spawns at `x=1.0`, moves with `vx < 0` (Left).

2.  **Intersection Configs**:
    *   **Intersection 1**: Restricted to **East-West** flow only.
    *   **Intersections 2-5**: Standard 4-way intersections.

3.  **Vehicle Physics**:
    *   **Speed**: Randomly assigned base speed +/- variance.
    *   **Multipliers**:
        *   🚑 **Emergency** (Ambulance/Police): **1.8x** speed.
        *   🏍️ **Motorbike**: **1.4x** speed.
        *   🚌 **Bus**: **0.7x** speed.
    *   **Traffic Lights**: Vehicles automatically slow to a stop (`vx=0, vy=0`) when approaching a red light.

### Visualization (`visul.html`)
A frontend validation tool that connects to all 5 WebSocket streams and renders them on HTML5 Canvases. It converts the abstract `x,y` coordinates (0-1) into pixel coordinates to animate vehicle movement and displays live traffic light states.
