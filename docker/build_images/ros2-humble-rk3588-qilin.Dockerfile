# ROS 2 Humble on RK3588 (arm64) + Ubuntu 22.04 — Qilin / OpenArm 工作区
#
# 前提：基础镜像 ybx.ubtrobot.com/ubuntu:22.04-ros2 已内置 ROS 2 Humble，
#       本文件不再添加 ros2 apt 源、不重复安装 ros-base。
#
# 构建（在含完整工作区的目录下，可将上下文设为仓库根）：
#   docker build -f ros2-humble-rk3588-qilin.Dockerfile -t ros2-humble-rk3588-qilin:latest .
#
# 运行示例见文件末尾。

FROM ybx.ubtrobot.com/ubuntu:22.04-ros2

# 基础镜像若以非 root USER 结束，后续 sed/apt 会 Permission denied
USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV WS_DIR=/root/ros2_ws
ENV ROS_DISTRO=humble

# ============================================================
# APT 镜像（22.04：sources.list 与 ubuntu.sources 并存）+ universe
# 本层合并：基础工具 + OpenArm 全仓 colcon 常见系统依赖（缺省曾导致 CMake/pkg-config 失败）
#   pkg-config | libwebsockets-dev | portaudio19-dev（Jammy 勿用 libportaudio-dev 虚包名）| libsamplerate0-dev
#   libgraphicsmagick++1-dev | graphicsmagick-libmagick-dev-compat
#   libjsoncpp-dev | libmosquitto-dev | libmosquittopp-dev
#   nlohmann-json3-dev | libcurl4-openssl-dev | libssl-dev | libyaml-cpp-dev | libeigen3-dev
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
      wget \
      sudo \
      vim \
      pkg-config \
      python3-pip \
      mesa-utils \
      libgl1 \
      libgl1-mesa-dri \
      libglx-mesa0 \
      libx11-6 \
      libxext6 \
      libxrender1 \
      libxtst6 \
      libxi6 \
      libxrandr2 \
      can-utils \
      libsocketcan2 \
      libsocketcan-dev \
      iproute2 \
      iputils-ping \
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
# 可选：Cyclone DDS RMW（板端常用；若基础镜像已默认 Cyclone 可删本 RUN）
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Qilin / MoveIt / 可视化 / ros2_control / SocketCAN
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-control-msgs \
    ros-humble-yaml-cpp-vendor \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-hardware-interface \
    ros-humble-controller-manager \
    ros-humble-joint-state-broadcaster \
    ros-humble-joint-trajectory-controller \
    ros-humble-moveit \
    ros-humble-moveit-servo \
    ros-humble-moveit-visual-tools \
    ros-humble-rviz2 \
    ros-humble-rviz-common \
    ros-humble-rviz-default-plugins \
    ros-humble-xacro \
    ros-humble-robot-state-publisher \
    ros-humble-joint-state-publisher \
    ros-humble-joint-state-publisher-gui \
    ros-humble-tf2-tools \
    ros-humble-ros2-socketcan \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# rosdep（在挂载工作区后可在容器内：rosdep install --from-paths src -y --ignore-src）
# init 默认指向 GitHub raw，国内/受限网络常超时：换 index + 将 yaml 指到 Gitee 同步仓库（勿用 gitee.com/ros/rosdistro，无该工程会 404）
# 使用 gitee.com/ros2cn/rosdistro（自 github.com/ros/rosdistro 同步，路径与 20-default.list 中 raw 一致）
# ============================================================
RUN set -eux; \
    if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
        rosdep init; \
    fi; \
    if [ -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
        sed -i 's|https://raw.githubusercontent.com/ros/rosdistro/master|https://gitee.com/ros2cn/rosdistro/raw/master|g' \
            /etc/ros/rosdep/sources.list.d/20-default.list; \
    fi; \
    attempt=1; \
    until rosdep update; do \
        attempt=$((attempt+1)); \
        if [ "$attempt" -gt 3 ]; then exit 1; fi; \
        sleep 15; \
    done

# ============================================================
# Shell 环境
# ============================================================
RUN grep -q "source /opt/ros/humble/setup.bash" /etc/bash.bashrc \
    || echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc

WORKDIR /root
CMD ["bash"]

# ============================================================
# 运行示例（RK3588 / Mali，勿使用 NVIDIA runtime）
#
# docker run -it --rm \
#   --net=host \
#   --ipc=host \
#   --privileged \
#   -v /dev:/dev \
#   -v /path/to/OpenArm:/root/ros2_ws/src:rw \
#   -v /tmp/.X11-unix:/tmp/.X11-unix \
#   -e DISPLAY=${DISPLAY} \
#   ros2-humble-rk3588-qilin:latest
#
# 仅使用 Panfrost 时可加：--device /dev/dri
#
# 宿主机（Ubuntu 22.04）对齐本镜像首层系统依赖时可执行（需已启用 universe）：
# sudo apt update && sudo apt install -y \
#   pkg-config build-essential cmake git libwebsockets-dev portaudio19-dev libsamplerate0-dev \
#   libgraphicsmagick++1-dev graphicsmagick-libmagick-dev-compat libjsoncpp-dev \
#   libmosquitto-dev libmosquittopp-dev nlohmann-json3-dev libcurl4-openssl-dev \
#   libssl-dev libyaml-cpp-dev libeigen3-dev
# ============================================================
