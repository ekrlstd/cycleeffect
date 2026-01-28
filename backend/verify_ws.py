import asyncio
import websockets

async def test_connection(intersection_id):
    if intersection_id == "":
        uri = "ws://localhost:8000/ws/traffic"
    else:
        uri = f"ws://localhost:8000/ws/traffic/{intersection_id}"
    try:
        async with websockets.connect(uri) as websocket:
            print(f"Connected to {uri}")
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f"[{intersection_id}] Received: {message[:100]}...")
            except asyncio.TimeoutError:
                print(f"[{intersection_id}] No message received within 5 seconds.")
            except Exception as e:
                print(f"[{intersection_id}] Error receiving message: {e}")
    except Exception as e:
        print(f"[{intersection_id}] Failed to connect: {e}")

async def main():
    tasks = [test_connection(i) for i in range(1, 6)]
    # Add a test for the default endpoint
    tasks.append(test_connection("")) 
    await asyncio.gather(*tasks)

if __name__ == "__main__":
    asyncio.run(main())
