from llama_cpp import Llama
import os

MODEL_PATH = "/Users/abdirashiidsammantar/Documents/models/qwen3-0.6b-q4_k_m.gguf"

if not os.path.exists(MODEL_PATH):
    print(f"Error: Model file not found at {MODEL_PATH}")
    exit(1)

print(f"Loading model from {MODEL_PATH}...")
try:
    llm = Llama(
        model_path=MODEL_PATH,
        n_ctx=2048,
        verbose=False
    )
    print("Model loaded successfully!")
    
    output = llm("Hello traffic", max_tokens=10)
    print("Inference test success:", output)
except Exception as e:
    print(f"Failed to load model: {e}")
