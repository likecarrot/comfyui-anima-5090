FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

WORKDIR /workspace


# ============================================================
# 系统基础依赖
# ============================================================

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    wget \
    curl \
    ca-certificates \
    openssh-server \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# AutoDL SSH
# ============================================================

RUN mkdir -p /var/run/sshd && \
    sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config


# ============================================================
# Python Virtual Environment
# ============================================================

RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"


# ============================================================
# Python 基础工具
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    --upgrade \
    pip \
    setuptools \
    wheel \
    -i https://mirrors.aliyun.com/pypi/simple


# ============================================================
# PyTorch
#
# RTX 5090 / Blackwell
# CUDA 13.0
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu130


# ============================================================
# 复制固定版本 ComfyUI
#
# ComfyUI 已经直接放在 GitHub 仓库中
# ============================================================

COPY ComfyUI /workspace/ComfyUI

WORKDIR /workspace/ComfyUI


# ============================================================
# ComfyUI Python dependencies
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    -r requirements.txt \
    -i https://mirrors.aliyun.com/pypi/simple


# ============================================================
# JupyterLab
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    "jupyterlab>=4.0" \
    ipywidgets \
    matplotlib \
    jupyterlab_language_pack_zh_CN \
    -i https://mirrors.aliyun.com/pypi/simple


# ============================================================
# ComfyUI 模型目录
# ============================================================

RUN mkdir -p \
    /workspace/ComfyUI/models/checkpoints \
    /workspace/ComfyUI/models/clip \
    /workspace/ComfyUI/models/vae \
    /workspace/ComfyUI/models/diffusion_models \
    /workspace/ComfyUI/models/loras \
    /workspace/ComfyUI/models/text_encoders \
    /workspace/ComfyUI/output \
    /workspace/ComfyUI/input


# ============================================================
# JupyterLab 工作目录
# ============================================================

RUN mkdir -p /workspace/notebooks


# ============================================================
# 启动脚本
# ============================================================

COPY start.sh /workspace/start.sh

RUN chmod +x /workspace/start.sh


# ============================================================
# 端口
# ============================================================

EXPOSE 8188
EXPOSE 8888


# ============================================================
# 不设置 ENTRYPOINT
# 不设置 CMD
#
# AutoDL 启动时会传入自己的 CMD
# ============================================================