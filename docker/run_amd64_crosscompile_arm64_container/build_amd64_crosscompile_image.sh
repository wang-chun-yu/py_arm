#!/usr/bin/env bash
# 构建 amd64 交叉编译 arm64 使用的开发镜像
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

DOCKERFILE_PATH="${SCRIPT_DIR}/ubuntu-amd64-crosscompile.Dockerfile"
IMAGE_TAG="${IMAGE_TAG:-amd64-crosscompile:v1.0.0}"
LOCAL_REGISTRY="${LOCAL_REGISTRY:-127.0.0.1:5000}"

if ! command -v docker >/dev/null 2>&1; then
  echo "错误: 未找到 docker 命令，请先安装 Docker。" >&2
  exit 1
fi

if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  echo "错误: Dockerfile 不存在: ${DOCKERFILE_PATH}" >&2
  exit 1
fi

echo "==> 构建镜像: ${IMAGE_TAG}"
echo "==> 使用基础镜像仓库: ${LOCAL_REGISTRY}"

docker build \
  --network host \
  --build-arg "LOCAL_REGISTRY=${LOCAL_REGISTRY}" \
  -f "${DOCKERFILE_PATH}" \
  -t "${IMAGE_TAG}" \
  "${REPO_ROOT}"

docker tag ${IMAGE_TAG} ${LOCAL_REGISTRY}/${IMAGE_TAG}
docker push ${LOCAL_REGISTRY}/${IMAGE_TAG}

echo "==> 构建完成: ${IMAGE_TAG}"
