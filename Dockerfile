FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /workspace

# ============================================================
# 系统基础依赖
# ============================================================

RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
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
# AutoDL SSH 基础配置
# ============================================================

RUN mkdir -p /var/run/sshd && \
    sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config


# ============================================================
# Python 虚拟环境
# ============================================================

RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"


# ============================================================
# 升级 Python 基础工具
# ============================================================

RUN pip install --upgrade \
    pip \
    setuptools \
    wheel \
    -i https://mirrors.aliyun.com/pypi/simple


# ============================================================
# 下载最新版 ComfyUI
# ============================================================

RUN git clone \
    https://github.com/Comfy-Org/ComfyUI.git \
    /workspace/ComfyUI

WORKDIR /workspace/ComfyUI


# ============================================================
# PyTorch
#
# RTX 5090 / Blackwell
# CUDA 13.0
# ============================================================

RUN pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu130


# ============================================================
# ComfyUI Python dependencies
# ============================================================

RUN pip install \
    -r requirements.txt \
    -i https://mirrors.aliyun.com/pypi/simple


# ============================================================
# JupyterLab
# ============================================================

RUN pip install \
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
# 复制启动脚本
# ============================================================

COPY start.sh /workspace/start.sh

RUN chmod +x /workspace/start.sh


# ============================================================
# 端口
#
# 8188  -> ComfyUI
# 8888  -> JupyterLab
# ============================================================

EXPOSE 8188
EXPOSE 8888


# ============================================================
# 注意：
#
# 不设置 ENTRYPOINT
# 不设置 CMD
#
# AutoDL 可以根据自己的启动机制执行命令。
# 如果需要手动启动：
#
# /workspace/start.sh
# ============================================================