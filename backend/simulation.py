import asyncio
import json
import random
import time
import uuid

class TrafficSimulator:
    def __init__(self, intersection_id: int):
        self.intersection_id = intersection_id
        self.objects = {}  # id -> object dict
        self.width = 1.0
        self.height = 1.0
        self.lanes = ["N1", "S1", "E1", "W1"]
        self.object_types = ["car", "taxi", "bus", "bicycle", "police_car", "ambulance", "motorbike"]
        
        # Traffic light state
        self.signal_state = "NS_GREEN"
        self.last_signal_change = time.time()
        self.signal_duration = 10.0  # seconds
        
        # Initialize with a few objects
        for _ in range(5):
            self.spawn_object()

    def spawn_object(self):
        obj_id = f"obj_{str(uuid.uuid4())[:8]}"
        obj_type = random.choice(self.object_types)
        
        # Random start position and lane
        lane = random.choice(self.lanes)
        
        # Simple logic: N/S lanes move Y, E/W lanes move X
        vx, vy = 0.0, 0.0
        x, y = 0.5, 0.5
        heading = 0
        
        # Base speed
        speed = 0.01 + random.random() * 0.02
        
        # Speed multipliers
        if obj_type in ["ambulance", "police_car"]:
            speed *= 1.8  # Emergency vehicles are significantly faster
        elif obj_type == "motorbike":
            speed *= 1.4  # Motorbikes are fast
        elif obj_type == "bus":
            speed *= 0.7  # Buses are slower
            
        if lane == "N1":
            x = 0.45
            y = 1.0
            vy = -speed
            heading = 180
        elif lane == "S1":
            x = 0.55
            y = 0.0
            vy = speed
            heading = 0
        elif lane == "E1":
            x = 0.0
            y = 0.45
            vx = speed
            heading = 90
        elif lane == "W1":
            x = 1.0
            y = 0.55
            vx = -speed
            heading = 270

        
        self.objects[obj_id] = {
            "id": obj_id,
            "type": obj_type,
            "x": x,
            "y": y,
            "vx": vx,
            "vy": vy,
            "baseVx": vx,
            "baseVy": vy,
            "heading": heading,
            "lane": lane,
            "confidence": 0.8 + random.random() * 0.2,
            "stopped": False
        }

    def update(self):
        current_time = time.time()
        
        # Update signal
        if current_time - self.last_signal_change > self.signal_duration:
            self.signal_state = "EW_GREEN" if self.signal_state == "NS_GREEN" else "NS_GREEN"
            self.last_signal_change = current_time
            
        # Spawn new objects occasionally
        if len(self.objects) < 15 and random.random() < 0.05:
            self.spawn_object()
            
        to_remove = []
        
        for obj_id, obj in self.objects.items():
            # Stop logic based on traffic light
            should_stop = False
            if obj["type"] in ["car", "taxi", "bus", "bicycle"]:
                if self.signal_state == "NS_GREEN" and obj["lane"] in ["E1", "W1"]:
                    # Check if approaching intersection center
                    if 0.3 < obj["x"] < 0.7 or 0.3 < obj["y"] < 0.7: 
                         # Simplified: stop if getting close to center and light is red for them
                         dist_to_center = ((obj["x"]-0.5)**2 + (obj["y"]-0.5)**2)**0.5
                         if dist_to_center < 0.3:
                            should_stop = True
                elif self.signal_state == "EW_GREEN" and obj["lane"] in ["N1", "S1"]:
                     dist_to_center = ((obj["x"]-0.5)**2 + (obj["y"]-0.5)**2)**0.5
                     if dist_to_center < 0.3:
                        should_stop = True
            
            if should_stop:
                obj["vx"] = 0
                obj["vy"] = 0
                obj["stopped"] = True
            else:
                obj["vx"] = obj["baseVx"]
                obj["vy"] = obj["baseVy"]
                obj["stopped"] = False
                
                # Move
                obj["x"] += obj["vx"]
                obj["y"] += obj["vy"]
            
            # Remove if out of bounds
            if not (-0.1 <= obj["x"] <= 1.1 and -0.1 <= obj["y"] <= 1.1):
                to_remove.append(obj_id)
                
        for obj_id in to_remove:
            del self.objects[obj_id]
            
    def get_state(self):
        timestamp = int(time.time() * 1000)
        object_list = list(self.objects.values())
        
        # Create events from objects (just copying all as detections for now)
        events = []
        for obj in object_list:
            events.append({
                "type": "detection",
                "objectType": obj["type"],
                "objectId": obj["id"],
                "x": obj["x"],
                "y": obj["y"],
                "vx": obj["vx"],
                "vy": obj["vy"],
                "heading": obj["heading"],
                "lane": obj["lane"],
                "confidence": obj["confidence"],
                "timestamp": timestamp
            })

        return {
            "type": "update",
            "events": events,
            "state": {
                "objects": object_list,
                "signalState": self.signal_state,
                "congestionLevel": len(object_list)
            },
            "timestamp": timestamp
        }
