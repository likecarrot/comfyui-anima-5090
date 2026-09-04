#!/bin/bash

set -e

echo "============================================================"
echo "        ComfyUI RTX 5090 Environment"
echo "============================================================"

echo ""
echo ">>> System information"
echo ""

echo "Kernel:"
uname -a || true

echo ""
echo "CUDA:"
nvcc --version || true

echo ""
echo "============================================================"
echo "        NVIDIA GPU"
echo "============================================================"

nvidia-smi || true

echo ""
echo "============================================================"
echo "        PyTorch"
echo "============================================================"

python - <<'PY'
import torch

print("PyTorch version :", torch.__version__)
print("Torch CUDA      :", torch.version.cuda)
print("CUDA available  :", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU count       :", torch.cuda.device_count())

    for i in range(torch.cuda.device_count()):
        gpu = torch.cuda.get_device_properties(i)

        print("")
        print("GPU", i)
        print("  Name          :", torch.cuda.get_device_name(i))
        print("  Compute       :", f"{gpu.major}.{gpu.minor}")
        print("  VRAM          :", round(gpu.total_memory / 1024**3, 2), "GB")

else:
    print("")
    print("WARNING: CUDA is NOT available.")
    print("Please check NVIDIA Container Toolkit / GPU runtime.")
PY

echo ""
echo "============================================================"
echo "        ComfyUI"
echo "============================================================"

cd /workspace/ComfyUI

echo "ComfyUI directory:"
pwd

echo ""
echo "Starting ComfyUI..."
echo ""

exec python main.py \
    --listen 0.0.0.0 \
    --port 8188