#
# buildx + docker-container 且 builder 使用宿主机网络时，FROM 建议用 127.0.0.1:5000，
# 避免 localhost 解析到 [::1] 而本机 registry 仅监听 IPv4 时出现 connection refused。
ARG LOCAL_REGISTRY=127.0.0.1:5000
FROM ${LOCAL_REGISTRY}/ros:humble

# 基础镜像若以非 root USER 结束，后续 sed/apt 会 Permission denied
USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV WS_DIR=/root/ros2_ws
ENV ROS_DISTRO=humble

# ============================================================
# APT 镜像（22.04：sources.list 与 ubuntu.sources 并存）+ universe
# 作为交叉编译镜像，仅保留构建链路必需依赖：
#   - 工具链/构建工具（build-essential/cmake/pkg-config 等）
#   - arm64 交叉编译工具链（aarch64-linux-gnu-gcc/g++ 等）
#   - Qt host 构建工具（moc/uic/rcc，交叉编时需在 amd64 主机执行）
#   - ros2 workspace 构建所需基础命令（git/sudo/python3-pip）
#   - py_arm 当前编译依赖的 -dev 包（websocket/audio/json/mqtt/ssl/yaml/eigen 等）
# 去除运行时/调试型依赖（如 X11/mesa/can-utils/iproute2/ping 等）。
# ============================================================
RUN set -eux; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i 's@http://archive.ubuntu.com/ubuntu@http://mirrors.tuna.tsinghua.edu.cn/ubuntu@g' /etc/apt/sources.list || true; \
      sed -i 's@http://security.ubuntu.com/ubuntu@http://mirrors.tuna.tsinghua.edu.cn/ubuntu@g' /etc/apt/sources.list || true; \
    fi; \
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      sed -i 's@http://archive.ubuntu.com/ubuntu@http://mirrors.tuna.tsinghua.edu.cn/ubuntu@g' /etc/apt/sources.list.d/ubuntu.sources || true; \
      sed -i 's@http://security.ubuntu.com/ubuntu@http://mirrors.tuna.tsinghua.edu.cn/ubuntu@g' /etc/apt/sources.list.d/ubuntu.sources || true; \
      if ! grep -qE '^Components:.*[[:space:]]universe' /etc/apt/sources.list.d/ubuntu.sources; then \
        sed -i 's/^Components:\(.*\)$/Components:\1 universe multiverse/' /etc/apt/sources.list.d/ubuntu.sources; \
      fi; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends software-properties-common; \
    add-apt-repository -y universe; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      locales \
      curl \
      gnupg2 \
      lsb-release \
      build-essential \
      cmake \
      git \
      sudo \
      pkg-config \
      binutils-aarch64-linux-gnu \
      gcc-aarch64-linux-gnu \
      g++-aarch64-linux-gnu \
      libc6-dev-arm64-cross \
      qtbase5-dev-tools \
      python3-pip \
      libsocketcan-dev \
      libwebsockets-dev \
      portaudio19-dev \
      libsamplerate0-dev \
      libgraphicsmagick++1-dev \
      graphicsmagick-libmagick-dev-compat \
      libjsoncpp-dev \
      libmosquitto-dev \
      libmosquittopp-dev \
      nlohmann-json3-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      libyaml-cpp-dev \
      libeigen3-dev \
    ; \
    locale-gen en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
# 构建/容器内 rosdep 避免访问 raw.githubusercontent.com 超时；与清华 ROS 源说明一致
ENV ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml

# ============================================================
# 工作区构建工具（若基础镜像已带齐，本层多为 no-op）
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-rosdep \
    python3-vcstool \
    python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# 用户信息
ARG USERNAME=chunyu
ARG USERPASSWORD=1
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEBIAN_FRONTEND=noninteractive
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo "$USERNAME:123" | chpasswd && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    chown -R $USER_UID:$USER_GID /home/$USERNAME && \
    chgrp -R $USERNAME /home/$USERNAME
# ============================================================
