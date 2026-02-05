#!/usr/bin/env python3
"""Generates the Flutter asset list for the TTS model files."""

import os

MODEL_DIR = "assets/tts-models/vits-piper-en_US-lessac-medium"
ESPEAK_DIR = f"{MODEL_DIR}/espeak-ng-data"

def main():
    # Get the script's parent directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)

    model_path = os.path.join(project_dir, MODEL_DIR)
    espeak_path = os.path.join(project_dir, ESPEAK_DIR)

    if not os.path.exists(model_path):
        print(f"Error: Model not found at {model_path}")
        print("Run ./scripts/setup_tts_model.sh first")
        return

    print("# Add these lines to pubspec.yaml under flutter: assets:")
    print()

    # Main model files
    for f in os.listdir(model_path):
        if os.path.isfile(os.path.join(model_path, f)):
            print(f"    - {MODEL_DIR}/{f}")

    # espeak-ng-data files
    for f in sorted(os.listdir(espeak_path)):
        if os.path.isfile(os.path.join(espeak_path, f)):
            print(f"    - {ESPEAK_DIR}/{f}")

if __name__ == "__main__":
    main()
