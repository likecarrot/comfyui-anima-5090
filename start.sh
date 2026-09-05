#!/bin/bash
set -e

cd /opt/ComfyUI

echo "======================================"
echo " ComfyUI Anima RTX 5090"
echo "======================================"

echo "ComfyUI:"
git rev-parse HEAD 2>/dev/null || true

echo "Manager:"
git -C custom_nodes/ComfyUI-Manager rev-parse HEAD 2>/dev/null || true

echo "Python:"
python --version

echo "PyTorch:"
python -c "import torch; print(torch.__version__)"

echo "CUDA:"
python -c "import torch; print(torch.version.cuda)"

echo "GPU:"
python -c "import torch; print(torch.cuda.get_device_name(0))"

echo "======================================"

exec python main.py \
    --listen 0.0.0.0 \
    --port 6006