#!/bin/bash
# Downloads the VITS-Piper TTS model for sherpa-onnx
# Run this script before building the app to bundle the voice model

set -e

MODEL_NAME="vits-piper-en_US-lessac-medium"
MODEL_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/${MODEL_NAME}.tar.bz2"
ASSETS_DIR="$(dirname "$0")/../assets/tts-models"

echo "=== CycleEffect TTS Model Setup ==="
echo ""

# Create assets directory
mkdir -p "$ASSETS_DIR"
cd "$ASSETS_DIR"

# Check if model already exists
if [ -d "$MODEL_NAME" ] && [ -f "$MODEL_NAME/en_US-lessac-medium.onnx" ]; then
    echo "✓ Model already downloaded at $ASSETS_DIR/$MODEL_NAME"
    exit 0
fi

echo "Downloading VITS-Piper voice model (~45MB)..."
echo "Model: $MODEL_NAME"
echo "URL: $MODEL_URL"
echo ""

# Download (follow redirects)
curl -L --progress-bar -o "${MODEL_NAME}.tar.bz2" "$MODEL_URL"

echo ""
echo "Extracting model..."
tar -xjf "${MODEL_NAME}.tar.bz2"

# Clean up
rm "${MODEL_NAME}.tar.bz2"

echo ""
echo "✓ Model downloaded successfully!"
echo "Location: $ASSETS_DIR/$MODEL_NAME"
echo ""
echo "Model files:"
ls -la "$MODEL_NAME/"
echo ""
echo "Next steps:"
echo "1. Run 'flutter pub get' to install dependencies"
echo "2. Build your app with 'flutter run'"
