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
#
# 使用 BuildKit pip cache
# 可以让 ACR 后续构建复用已经下载的 Python wheel
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
#
# 单独安装 PyTorch，避免被 ComfyUI requirements 覆盖
# ============================================================

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu130


# ============================================================
# 创建 ComfyUI 目录
# ============================================================

RUN mkdir -p /workspace/ComfyUI

WORKDIR /workspace/ComfyUI


# ============================================================
# 第一阶段：只复制 requirements.txt
#
# 重要优化：
#
# 如果以后只修改 ComfyUI 源码，而 requirements.txt 没变化，
# Docker 可以直接复用下面这一层，不需要重新 pip install。
# ============================================================

COPY ComfyUI/requirements.txt /workspace/ComfyUI/requirements.txt


# ============================================================
# 安装 ComfyUI Python dependencies
#
# 使用 BuildKit pip cache
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
# 第二阶段：复制完整 ComfyUI
#
# 注意：
# 这一层放在 Python dependencies 后面。
#
# 修改 ComfyUI 源码时，不会导致上面的 pip install
# 重新执行。
# ============================================================

COPY ComfyUI /workspace/ComfyUI


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
#
# 8188 -> ComfyUI
# 8888 -> JupyterLab
# ============================================================

EXPOSE 8188
EXPOSE 8888


# ============================================================
# 不设置 ENTRYPOINT
# 不设置 CMD
#
# AutoDL 启动时传入自己的 CMD
#
# 手动启动 ComfyUI：
# /workspace/start.sh
#
# 手动启动 JupyterLab：
# jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser
# ============================================================