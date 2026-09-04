FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /workspace

# 基础依赖
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    curl \
    ca-certificates \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# 创建 Python 虚拟环境
RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# 升级 pip
RUN pip install --upgrade pip setuptools wheel

# 获取最新版 ComfyUI
RUN git clone https://github.com/Comfy-Org/ComfyUI.git /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

# 安装 PyTorch
RUN pip install torch torchvision torchaudio

# 安装 ComfyUI Python 依赖
RUN pip install -r requirements.txt

# 创建模型目录
RUN mkdir -p \
    models/checkpoints \
    models/clip \
    models/vae \
    models/diffusion_models \
    models/loras \
    models/text_encoders \
    output \
    input

EXPOSE 8188

CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]