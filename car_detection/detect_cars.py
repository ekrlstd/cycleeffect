"""
Car Detection with ByteTrack Tracking
Uses YOLOv8 for detection and ByteTrack for multi-object tracking
"""

from ultralytics import YOLO
import supervision as sv
import cv2
from pathlib import Path
import argparse
import numpy as np


# Vehicle class IDs in COCO dataset
VEHICLE_CLASSES = {
    2: 'car',
    3: 'motorcycle',
    5: 'bus',
    7: 'truck'
}

# Colors for different vehicle types (BGR format)
VEHICLE_COLORS = {
    2: (0, 255, 0),    # Green for cars
    3: (255, 0, 255),  # Magenta for motorcycles
    5: (255, 165, 0),  # Orange for buses
    7: (0, 0, 255),    # Red for trucks
}


def detect_vehicles_bytetrack(model, video_path, output_dir, conf_threshold=0.5):
    """
    Run YOLO detection with ByteTrack tracking on a video.

    Args:
        model: YOLO model instance
        video_path: Path to input video
        output_dir: Directory to save output video
        conf_threshold: Confidence threshold for detections
    """
    video_path = Path(video_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Initialize ByteTrack tracker
    byte_tracker = sv.ByteTrack(
        track_activation_threshold=0.25,
        lost_track_buffer=30,
        minimum_matching_threshold=0.8,
        frame_rate=30
    )

    # Initialize annotators
    box_annotator = sv.BoxAnnotator(
        thickness=2
    )
    label_annotator = sv.LabelAnnotator(
        text_scale=0.5,
        text_thickness=1,
        text_padding=5
    )
    trace_annotator = sv.TraceAnnotator(
        thickness=2,
        trace_length=50
    )

    # Open video
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return None

    # Get video properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS)) or 30
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # Setup output video writer
    output_filename = f"tracked_{video_path.stem}.mp4"
    output_path = output_dir / output_filename
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(str(output_path), fourcc, fps, (width, height))

    frame_count = 0
    total_detections = 0
    unique_track_ids = set()

    print(f"Processing: {video_path.name} ({total_frames} frames)")
    print(f"  Using ByteTrack for multi-object tracking")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Run YOLO detection (not tracking - ByteTrack handles tracking)
        results = model(frame, conf=conf_threshold, verbose=False)[0]

        # Convert YOLO results to supervision Detections
        detections = sv.Detections.from_ultralytics(results)

        # Filter for vehicle classes only
        vehicle_mask = np.isin(detections.class_id, list(VEHICLE_CLASSES.keys()))
        detections = detections[vehicle_mask]

        # Update tracker with detections
        detections = byte_tracker.update_with_detections(detections)

        # Track unique IDs
        if detections.tracker_id is not None:
            unique_track_ids.update(detections.tracker_id.tolist())

        # Create labels with track ID and vehicle type
        labels = []
        for i in range(len(detections)):
            class_id = detections.class_id[i]
            tracker_id = detections.tracker_id[i] if detections.tracker_id is not None else None
            confidence = detections.confidence[i]

            vehicle_type = VEHICLE_CLASSES.get(class_id, 'vehicle')
            if tracker_id is not None:
                label = f"#{tracker_id} {vehicle_type} {confidence:.2f}"
            else:
                label = f"{vehicle_type} {confidence:.2f}"
            labels.append(label)

        total_detections += len(detections)

        # Annotate frame
        annotated_frame = frame.copy()

        # Draw traces (trajectory paths)
        annotated_frame = trace_annotator.annotate(
            scene=annotated_frame,
            detections=detections
        )

        # Draw bounding boxes
        annotated_frame = box_annotator.annotate(
            scene=annotated_frame,
            detections=detections
        )

        # Draw labels
        annotated_frame = label_annotator.annotate(
            scene=annotated_frame,
            detections=detections,
            labels=labels
        )

        # Add frame info overlay
        info_text = f"Frame: {frame_count} | Vehicles: {len(detections)} | Unique IDs: {len(unique_track_ids)}"
        cv2.putText(annotated_frame, info_text, (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

        out.write(annotated_frame)
        frame_count += 1

        # Progress update every 30 frames
        if frame_count % 30 == 0:
            print(f"  Processed {frame_count}/{total_frames} frames | Active tracks: {len(unique_track_ids)}")

    cap.release()
    out.release()

    print(f"  Completed: {total_detections} detections across {frame_count} frames")
    print(f"  Unique vehicles tracked: {len(unique_track_ids)}")
    print(f"  Saved to: {output_path}")

    return {
        'video': video_path.name,
        'frames': frame_count,
        'detections': total_detections,
        'unique_tracks': len(unique_track_ids),
        'output': str(output_path)
    }


def main():
    parser = argparse.ArgumentParser(description='Detect and track vehicles using YOLOv8 + ByteTrack')
    parser.add_argument('--input', '-i', type=str,
                        default='sample_videos',
                        help='Input video file or directory')
    parser.add_argument('--output', '-o', type=str,
                        default='output',
                        help='Output directory for processed videos')
    parser.add_argument('--model', '-m', type=str,
                        default='yolov8n.pt',
                        help='YOLO model to use (yolov8n.pt, yolov8s.pt, yolov8m.pt, etc.)')
    parser.add_argument('--conf', '-c', type=float,
                        default=0.4,
                        help='Confidence threshold (0-1)')
    parser.add_argument('--limit', '-l', type=int,
                        default=None,
                        help='Limit number of videos to process')

    args = parser.parse_args()

    # Load YOLO model
    print(f"Loading YOLO model: {args.model}")
    model = YOLO(args.model)

    input_path = Path(args.input)

    # Resolve relative paths to script directory
    if not input_path.is_absolute():
        script_dir = Path(__file__).parent
        input_path = script_dir / input_path

    if input_path.is_file():
        # Process single video
        detect_vehicles_bytetrack(model, input_path, args.output, args.conf)
    elif input_path.is_dir():
        # Process all videos in directory
        video_extensions = {'.avi', '.mp4', '.mov', '.mkv'}
        videos = sorted([f for f in input_path.iterdir() if f.suffix.lower() in video_extensions])

        if args.limit:
            videos = videos[:args.limit]

        print(f"Found {len(videos)} videos to process")

        results = []
        for i, video in enumerate(videos, 1):
            print(f"\n[{i}/{len(videos)}] ", end="")
            result = detect_vehicles_bytetrack(model, video, args.output, args.conf)
            if result:
                results.append(result)

        # Summary
        print("\n" + "="*60)
        print("PROCESSING COMPLETE - ByteTrack Multi-Object Tracking")
        print("="*60)
        print(f"Videos processed: {len(results)}")
        print(f"Total detections: {sum(r['detections'] for r in results)}")
        print(f"Total unique tracks: {sum(r['unique_tracks'] for r in results)}")
        print(f"Output directory: {args.output}")
    else:
        print(f"Error: {input_path} not found")


if __name__ == "__main__":
    main()
