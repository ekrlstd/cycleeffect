from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from sse_starlette.sse import EventSourceResponse
import httpx
import websockets
import asyncio
import json
import os
from simulation import TrafficSimulator
from slm_service import generate_narration

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create 5 independent simulators
simulators = {i: TrafficSimulator(i) for i in range(1, 6)}

@app.on_event("startup")
async def startup_event():
    # Start the simulation loop in the background
    asyncio.create_task(run_simulations())

async def run_simulations():
    while True:
        for sim in simulators.values():
            sim.update()
        await asyncio.sleep(0.1)  # 10 Hz update rate

@app.get("/")
async def get():
    return FileResponse(os.path.join(os.path.dirname(__file__), "index.html"))

@app.get("/visual")
async def get_visual():
    return FileResponse(os.path.join(os.path.dirname(__file__), "visul.html"))


# ============= NARRATION SSE ENDPOINT =============

async def narration_generator(intersection_id: int):
    """
    Generator that buffers 10 seconds of traffic data,
    sends to SLM for narration, and yields the result.
    Repeats every 10 seconds.
    """
    if intersection_id not in simulators:
        yield {"event": "error", "data": json.dumps({"error": "Intersection not found"})}
        return
    
    simulator = simulators[intersection_id]
    buffer_duration = 10  # seconds (changed from 20)
    sample_rate = 10  # Hz (matches simulator update rate)
    samples_needed = buffer_duration * sample_rate
    
    while True:
        # Collect traffic data for 10 seconds
        traffic_buffer = []
        for _ in range(samples_needed):
            state = simulator.get_state()
            traffic_buffer.append(state)
            await asyncio.sleep(1.0 / sample_rate)
        
        # Generate narration using SLM
        try:
            narration = generate_narration(traffic_buffer, intersection_id=intersection_id)
            yield {
                "event": "narration",
                "data": json.dumps({
                    "text": narration,
                    "intersection_id": intersection_id,
                    "timestamp": traffic_buffer[-1]["timestamp"] if traffic_buffer else 0
                })
            }
        except Exception as e:
            print(f"Narration generation error: {e}")
            yield {
                "event": "narration",
                "data": json.dumps({
                    "text": "Traffic update unavailable.",
                    "intersection_id": intersection_id,
                    "error": str(e)
                })
            }


@app.get("/narration/{intersection_id}")
async def narration_stream(intersection_id: int):
    """
    SSE endpoint that streams traffic narrations every 20 seconds.
    
    Args:
        intersection_id: 1-5 for different intersections
    
    Returns:
        Server-Sent Events stream with narration text
    """
    return EventSourceResponse(narration_generator(intersection_id))


# ============= WEBSOCKET ENDPOINTS =============

@app.websocket("/ws/traffic")
async def websocket_traffic_default(websocket: WebSocket):
    # Default to intersection 1 for backward compatibility
    await websocket_traffic_endpoint(websocket, 1)

@app.websocket("/ws/traffic/{intersection_id}")
async def websocket_traffic_endpoint(websocket: WebSocket, intersection_id: int):
    await websocket.accept()
    
    if intersection_id not in simulators:
        await websocket.close(code=4004, reason="Intersection not found")
        return

    simulator = simulators[intersection_id]
    
    try:
        while True:
            # Get current state from simulator
            state = simulator.get_state()
            await websocket.send_json(state)
            await asyncio.sleep(0.1)  # Send updates at 10 Hz
            
    except WebSocketDisconnect:
        print(f"Client disconnected from intersection {intersection_id}")
    except Exception as e:
        print(f"Error in websocket for intersection {intersection_id}: {e}")
        try:
            await websocket.close()
        except:
            pass

