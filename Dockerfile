FROM nvidia/cuda:13.0.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /opt

# System
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.12 /usr/local/bin/python

# PyTorch CUDA 13
RUN python -m pip install --break-system-packages \
    torch==2.12.1 \
    torchvision==0.27.1 \
    torchaudio==2.11.0 \
    --index-url https://download.pytorch.org/whl/cu130

# ComfyUI
COPY ComfyUI /opt/ComfyUI

WORKDIR /opt/ComfyUI

RUN python -m pip install --break-system-packages \
    -r requirements.txt

# ComfyUI Manager
RUN git clone https://github.com/Comfy-Org/ComfyUI-Manager.git \
    custom_nodes/ComfyUI-Manager \
    && cd custom_nodes/ComfyUI-Manager \
    && git checkout f82970b7cb63ad44928308f980a1d38fda103cbb \
    && python -m pip install --break-system-packages \
       -r requirements.txt

# Anima checkpoint
COPY models/unet/unholydesiremixdarksere.1kmd.safetensors \
     /opt/ComfyUI/models/unet/

# Remove Python cache
RUN find /opt/ComfyUI \
    -type d -name "__pycache__" \
    -prune -exec rm -rf {} +

EXPOSE 6006


COPY start.sh /opt/start.sh

RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]