#!/bin/bash
# Dockerfile 中 FROM ${LOCAL_REGISTRY}/ros:humble 需在构建时能访问宿主机上的 registry。
# docker-container 驱动若 BuildKit 容器为 bridge 网络，127.0.0.1 指向容器自身 → connection refused。
# 必须使用 --driver-opt network=host；若曾用旧选项创建过 mybuilder，容器会一直停留在 bridge，需删掉重建。
set -euo pipefail

tag=localhost:5000/runtime/py_arm/system:py_arm-ros2-humble-v1.0.0

# 与 Dockerfile 中 LOCAL_REGISTRY 一致；registry 不在本机时可 export LOCAL_REGISTRY=192.168.x.x:5000
LOCAL_REGISTRY="${LOCAL_REGISTRY:-127.0.0.1:5000}"

ensure_mybuilder_host_network() {
  if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
    docker buildx create --use --bootstrap --name mybuilder \
      --driver docker-container \
      --driver-opt network=host
    return 0
  fi

  docker buildx use mybuilder
  docker buildx inspect --bootstrap >/dev/null

  local ctn
  ctn="$(docker ps --filter 'name=buildx_buildkit_mybuilder' --format '{{.Names}}' | head -n1)"
  if [[ -z "${ctn}" ]]; then
    echo "未找到 BuildKit 容器，重建 mybuilder（network=host）..." >&2
    docker buildx rm mybuilder >/dev/null 2>&1 || true
    docker buildx create --use --bootstrap --name mybuilder \
      --driver docker-container \
      --driver-opt network=host
    return 0
  fi

  local nm
  nm="$(docker inspect "${ctn}" --format '{{.HostConfig.NetworkMode}}')"
  if [[ "${nm}" != "host" ]]; then
    echo "检测到 BuildKit 容器「${ctn}」网络为「${nm}」（非 host），无法访问宿主机 ${LOCAL_REGISTRY}。" >&2
    echo "正在删除并重建 mybuilder（--driver-opt network=host）..." >&2
    docker buildx stop mybuilder >/dev/null 2>&1 || true
    docker buildx rm mybuilder
    docker buildx create --use --bootstrap --name mybuilder \
      --driver docker-container \
      --driver-opt network=host
  fi
}

ensure_mybuilder_host_network

if ! curl -sf --max-time 3 "http://${LOCAL_REGISTRY}/v2/" >/dev/null; then
  echo "错误: 无法访问 http://${LOCAL_REGISTRY}/v2/" >&2
  echo "请先执行: ./docker/run_registry/run_registry.sh" >&2
  exit 1
fi

docker buildx build --network=host \
  --platform linux/arm64,linux/amd64 \
  --build-arg "LOCAL_REGISTRY=${LOCAL_REGISTRY}" \
  -f docker/build_images/ros2-humble-py_arm.Dockerfile \
  -t "$tag" \
  --push \
  .
