from simulation import TrafficSimulator
import time

def test_sim():
    sim = TrafficSimulator(1)
    print(f"Initial objects: {len(sim.objects)}")
    
    for i in range(10):
        sim.update()
        state = sim.get_state()
        obj_count = len(state['state']['objects'])
        print(f"Step {i}: {obj_count} objects")
        if obj_count > 0:
            first_obj = state['state']['objects'][0]
            print(f"  - Obj {first_obj['id']} ({first_obj['type']}) at ({first_obj['x']:.2f}, {first_obj['y']:.2f})")
        else:
            print("  - No objects!")
            
if __name__ == "__main__":
    test_sim()
