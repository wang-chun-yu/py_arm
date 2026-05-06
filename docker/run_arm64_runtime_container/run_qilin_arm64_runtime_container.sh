#!/usr/bin/env bash
#   Copyright (C) 2025 All rights reserved.
#   FileName      ：run_ros2_x86_container.sh
#   Author        ：congleetea
#   Email         ：congleetea@163.com
#   Date          ：2025年05月27日
#   Description   ：更新ROS2交叉编译镜像容器

set -e

docker login -u ubh -p ubtubt123 ybx.ubtrobot.com

docker compose  -f qilin_arm64_runtime_docker-compose.yml pull

docker compose -f qilin_arm64_runtime_docker-compose.yml up -d

docker exec -it -u ubt -w /home/ubt/ qilin_arm64_runtime bash
