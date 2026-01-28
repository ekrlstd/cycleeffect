#!/bin/bash
set -e

# Usage: ./compile_android.sh <input_model_dir> <output_name>
# Example: ./compile_android.sh ~/.cache/huggingface/hub/models--embedl--gemma-3-270m-it-FlashHead/snapshots/<hash> gemma-270m

MODEL_PATH="$1"
OUTPUT_NAME="${2:-model}"

if [ -z "$MODEL_PATH" ]; then
    echo "Usage: $0 <path_to_model_directory> [output_name]"
    echo "This script converts a Hugging Face model to GGUF format for use on Android (llama.cpp)."
    exit 1
fi

TOOLS_DIR="$(pwd)/tools/llama.cpp"
VENV_PYTHON="$(pwd)/venv/bin/python"
TEMP_DIR="temp_conversion_model"

echo "=== Preparing for Android Compilation ==="
echo "Input Model: $MODEL_PATH"
echo "Output Name: $OUTPUT_NAME"

# 1. Prepare Temporary Directory
echo "Creating temporary workspace..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy files. Dereference symlinks to ensure we get actual files (if possible)
cp -rL "$MODEL_PATH"/* "$TEMP_DIR/" || echo "Warning: Some files could not be copied. specific errors above."

# Check for weights
if [ -z "$(find "$TEMP_DIR" -name "*.safetensors" -o -name "*.bin" -o -name "*.pt")" ]; then
    echo "ERROR: No weight files (*.safetensors, *.bin, *.pt) found in copy!"
    echo "Please check if the source directory '$MODEL_PATH' contains the actual model weights."
    echo "Note: Hugging Face cache sometimes separates blobs. Provide the directory containing the actual weight files."
    exit 1
fi

# 2. Patch Architecture if needed (FlashHead -> Standard)
CONFIG_FILE="$TEMP_DIR/config.json"
if grep -q "FlashHead" "$CONFIG_FILE"; then
    echo "Detected FlashHead architecture. Patching config.json to mimic standard architecture for conversion..."
    
    # Patch Gemma3/FlashHead -> Gemma 2
    sed -i 's/FlashHeadGemma3ForCausalLM/Gemma2ForCausalLM/g' "$CONFIG_FILE"
    sed -i 's/flash_head_gemma3_text/gemma2/g' "$CONFIG_FILE"
    
    # Patch Llama FlashHead -> Llama
    sed -i 's/FlashHeadLlamaForCausalLM/LlamaForCausalLM/g' "$CONFIG_FILE"
    sed -i 's/flash_head_llama/llama/g' "$CONFIG_FILE"
    
    # Patch Qwen FlashHead -> Qwen3
    sed -i 's/FlashHeadQwen3ForCausalLM/Qwen3ForCausalLM/g' "$CONFIG_FILE"
    sed -i 's/flash_head_qwen3/qwen3/g' "$CONFIG_FILE"
    
    echo "Patched config.json."
fi

# 3. Create Output Directory
mkdir -p models

# 4. Convert to GGUF (FP16)
echo "=== Converting to GGUF (FP16) ==="
export PYTHONPATH="$TOOLS_DIR/gguf-py:$PYTHONPATH"
$VENV_PYTHON "$TOOLS_DIR/convert_hf_to_gguf.py" "$TEMP_DIR" --outfile "models/${OUTPUT_NAME}-f16.gguf"

# 5. Quantize for Mobile (Q4_K_M)
echo "=== Quantizing to Q4_K_M (Recommended for Android) ==="
QUANTIZE_BIN="$TOOLS_DIR/build/bin/llama-quantize"

if [ ! -f "$QUANTIZE_BIN" ]; then
    echo "Quantize tool not found at $QUANTIZE_BIN. Attempting to locate..."
    QUANTIZE_BIN=$(find "$TOOLS_DIR" -name llama-quantize | head -n 1)
fi

if [ -f "$QUANTIZE_BIN" ]; then
    "$QUANTIZE_BIN" "models/${OUTPUT_NAME}-f16.gguf" "models/${OUTPUT_NAME}-q4_k_m.gguf" Q4_K_M
    echo "Success! Optimized model saved to: models/${OUTPUT_NAME}-q4_k_m.gguf"
else
    echo "Error: llama-quantize tool not found. Could not quantize."
    echo "You can still use the FP16 model: models/${OUTPUT_NAME}-f16.gguf"
fi

echo "=== Done ==="
echo "To run on Android:"
echo "1. Copy 'models/${OUTPUT_NAME}-q4_k_m.gguf' to your device."
echo "2. Use llama.cpp Android app or library to load the model."
