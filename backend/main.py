from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import websockets
import asyncio
import json
import os
from simulation import TrafficSimulator

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

# Keep the original proxy endpoint if strictly needed, but shifting focus to simulation
# as per request "i want to have 5 different endpoints which simulates different intersection"
# We will expose the simulation endpoints.

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
