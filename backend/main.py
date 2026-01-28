from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
import httpx
import websockets
import asyncio
import json
import os

app = FastAPI()

@app.get("/")
async def get():
    return FileResponse(os.path.join(os.path.dirname(__file__), "index.html"))

TOKEN_URL = "https://gxziopzriagwbiefmrwi.supabase.co/functions/v1/traffic-feed/token"
STREAM_URL = "wss://gxziopzriagwbiefmrwi.supabase.co/functions/v1/traffic-feed/stream"
API_KEY = "demo-traffic-feed-key"

async def get_traffic_token():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            TOKEN_URL,
            json={"apiKey": API_KEY},
            headers={"Content-Type": "application/json"}
        )
        response.raise_for_status()
        data = response.json()
        return data["token"]

@app.websocket("/ws/traffic")
async def websocket_traffic_endpoint(client_websocket: WebSocket):
    await client_websocket.accept()
    
    try:
        # 1. Get the token
        token = await get_traffic_token()
        print(f"Got token: {token[:10]}...") 
        
        # 2. Connect to upstream WebSocket
        upstream_url = f"{STREAM_URL}?token={token}"
        
        async with websockets.connect(upstream_url) as upstream_websocket:
            print("Connected to upstream WebSocket")
            
            try:
                while True:
                    # Receive from upstream
                    message = await upstream_websocket.recv()
                    # Forward to client
                    await client_websocket.send_text(message)
            except websockets.exceptions.ConnectionClosed:
                print("Upstream connection closed")
                await client_websocket.close()
                
    except Exception as e:
        print(f"Error in websocket proxy: {e}")
        try:
            await client_websocket.close()
        except:
            pass
