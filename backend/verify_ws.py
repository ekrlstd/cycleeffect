import asyncio
import websockets

async def test_connection():
    uri = "ws://localhost:8000/ws/traffic"
    try:
        async with websockets.connect(uri) as websocket:
            print(f"Connected to {uri}")
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=10)
                print(f"Received message: {message[:100]}...")
            except asyncio.TimeoutError:
                print("No message received within 10 seconds.")
            except Exception as e:
                print(f"Error receiving message: {e}")
    except Exception as e:
        print(f"Failed to connect: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection())
