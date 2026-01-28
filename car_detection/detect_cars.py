"""
YOLO Car Detection on Highway Traffic Videos
Uses YOLOv8 pre-trained model to detect vehicles in video footage
"""

from ultralytics import YOLO
import cv2
from pathlib import Path
import argparse


# Vehicle class IDs in COCO dataset
VEHICLE_CLASSES = {
    2: 'car',
    3: 'motorcycle',
    5: 'bus',
    7: 'truck'
}


def detect_vehicles_in_video(model, video_path, output_dir, conf_threshold=0.5):
    """
    Run YOLO detection on a video and save annotated output.

    Args:
        model: YOLO model instance
        video_path: Path to input video
        output_dir: Directory to save output video
        conf_threshold: Confidence threshold for detections
    """
    video_path = Path(video_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Open video
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return None

    # Get video properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # Setup output video writer
    output_path = output_dir / f"detected_{video_path.name}"
    # Use mp4v codec for better compatibility
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(str(output_path).replace('.avi', '.mp4'), fourcc, fps, (width, height))

    frame_count = 0
    total_detections = 0

    print(f"Processing: {video_path.name} ({total_frames} frames)")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Run YOLO tracking (more stable than detection alone)
        results = model.track(frame, conf=conf_threshold, persist=True, verbose=False)

        # Process detections
        for result in results:
            boxes = result.boxes
            if boxes is None:
                continue
            for box in boxes:
                cls_id = int(box.cls[0])

                # Only process vehicle classes
                if cls_id in VEHICLE_CLASSES:
                    conf = float(box.conf[0])
                    x1, y1, x2, y2 = map(int, box.xyxy[0])

                    # Get track ID if available
                    track_id = ""
                    if box.id is not None:
                        track_id = f" #{int(box.id[0])}"

                    # Draw bounding box
                    color = (0, 0, 255)  # Red for vehicles
                    cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

                    # Draw label (smaller text)
                    label = f"{VEHICLE_CLASSES[cls_id]}{track_id}"
                    (label_width, label_height), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.35, 1)
                    cv2.rectangle(frame, (x1, y1 - label_height - 6), (x1 + label_width, y1), color, -1)
                    cv2.putText(frame, label, (x1, y1 - 3), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1)

                    total_detections += 1

        out.write(frame)
        frame_count += 1

        # Progress update every 30 frames
        if frame_count % 30 == 0:
            print(f"  Processed {frame_count}/{total_frames} frames...")

    cap.release()
    out.release()

    print(f"  Completed: {total_detections} vehicle detections")
    print(f"  Saved to: {output_path}")

    return {
        'video': video_path.name,
        'frames': frame_count,
        'detections': total_detections,
        'output': str(output_path)
    }


def main():
    parser = argparse.ArgumentParser(description='Detect vehicles in highway traffic videos using YOLO')
    parser.add_argument('--input', '-i', type=str,
                        default='videos/video',
                        help='Input video file or directory')
    parser.add_argument('--output', '-o', type=str,
                        default='output',
                        help='Output directory for processed videos')
    parser.add_argument('--model', '-m', type=str,
                        default='yolov8n.pt',
                        help='YOLO model to use (yolov8n.pt, yolov8s.pt, yolov8m.pt, etc.)')
    parser.add_argument('--conf', '-c', type=float,
                        default=0.5,
                        help='Confidence threshold (0-1)')
    parser.add_argument('--limit', '-l', type=int,
                        default=None,
                        help='Limit number of videos to process')

    args = parser.parse_args()

    # Load YOLO model
    print(f"Loading YOLO model: {args.model}")
    model = YOLO(args.model)

    input_path = Path(args.input)

    if input_path.is_file():
        # Process single video
        detect_vehicles_in_video(model, input_path, args.output, args.conf)
    elif input_path.is_dir():
        # Process all videos in directory
        video_extensions = {'.avi', '.mp4', '.mov', '.mkv'}
        videos = [f for f in input_path.iterdir() if f.suffix.lower() in video_extensions]

        if args.limit:
            videos = videos[:args.limit]

        print(f"Found {len(videos)} videos to process")

        results = []
        for i, video in enumerate(videos, 1):
            print(f"\n[{i}/{len(videos)}] ", end="")
            result = detect_vehicles_in_video(model, video, args.output, args.conf)
            if result:
                results.append(result)

        # Summary
        print("\n" + "="*50)
        print("PROCESSING COMPLETE")
        print("="*50)
        print(f"Videos processed: {len(results)}")
        print(f"Total detections: {sum(r['detections'] for r in results)}")
        print(f"Output directory: {args.output}")
    else:
        print(f"Error: {input_path} not found")


if __name__ == "__main__":
    main()
