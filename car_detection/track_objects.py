import argparse
import supervision as sv
from ultralytics import YOLO
import numpy as np
import os

def process_video(source_path, target_path, model_path="yolov8n.pt"):
    print(f"Loading model: {model_path}")
    model = YOLO(model_path)
    
    print("Initializing tracker...")
    tracker = sv.ByteTrack()
    
    box_annotator = sv.BoxAnnotator()
    label_annotator = sv.LabelAnnotator()

    def callback(frame: np.ndarray, index: int) -> np.ndarray:
        results = model(frame, verbose=False)[0]
        detections = sv.Detections.from_ultralytics(results)
        detections = tracker.update_with_detections(detections)
        
        labels = []
        for tracker_id, class_id in zip(detections.tracker_id, detections.class_id):
            class_name = model.model.names[class_id]
            labels.append(f"#{tracker_id} {class_name}")
        
        annotated_frame = box_annotator.annotate(scene=frame.copy(), detections=detections)
        annotated_frame = label_annotator.annotate(scene=annotated_frame, detections=detections, labels=labels)
        return annotated_frame

    print(f"Processing video: {source_path} -> {target_path}")
    sv.process_video(
        source_path=source_path,
        target_path=target_path,
        callback=callback
    )
    print("Processing complete.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Multi-Object Tracking with YOLOv8 and ByteTrack")
    parser.add_argument("--source", type=str, required=True, help="Path to source video")
    parser.add_argument("--output", type=str, required=True, help="Path to output video")
    parser.add_argument("--model", type=str, default="yolov8n.pt", help="YOLOv8 model path")
    
    args = parser.parse_args()
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    process_video(args.source, args.output, args.model)
