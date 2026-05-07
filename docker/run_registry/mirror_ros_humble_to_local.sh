#!/bin/bash
# 从 Docker Hub 分别拉取 amd64 / arm64 的 ros 镜像，推送到本地 registry，再合并为多架构 tag。
# 适用于无法使用 imagetools create 直连 Hub、或本地已有单架构 humble 需升级为 manifest list 的场景。
# 依赖：docker manifest（experimental）；本地 registry 已启动（run_registry.sh）。
# HTTP 私有库需在 manifest create/push 上使用 --insecure（脚本默认开启，可通过 USE_INSECURE_REGISTRY=0 关闭）。
# 用法：./mirror_ros_humble_to_local.sh
#       REGISTRY=192.168.1.10:5000 ./mirror_ros_humble_to_local.sh
#       SRC_IMAGE=ros:humble-ros-base REPO_NAME=ros ./mirror_ros_humble_to_local.sh
set -euo pipefail

REGISTRY="${REGISTRY:-localhost:5000}"
SRC_IMAGE="${SRC_IMAGE:-ros:humble}"
REPO_NAME="${REPO_NAME:-ros}"

TAG_BASE="${SRC_IMAGE##*:}"
TAG_AMD64="${TAG_BASE}-amd64"
TAG_ARM64="${TAG_BASE}-arm64"

DST_REPO="${REGISTRY}/${REPO_NAME}"
DST_AMD64="${DST_REPO}:${TAG_AMD64}"
DST_ARM64="${DST_REPO}:${TAG_ARM64}"
DST_MULTI="${DST_REPO}:${TAG_BASE}"

INSECURE=()
if [[ "${USE_INSECURE_REGISTRY:-1}" == "1" ]]; then
  INSECURE+=(--insecure)
fi

echo ">>> pull linux/amd64 ${SRC_IMAGE}"
docker pull --platform linux/amd64 "${SRC_IMAGE}"
docker tag "${SRC_IMAGE}" "${DST_AMD64}"
docker push "${DST_AMD64}"

echo ">>> pull linux/arm64 ${SRC_IMAGE}"
docker pull --platform linux/arm64 "${SRC_IMAGE}"
docker tag "${SRC_IMAGE}" "${DST_ARM64}"
docker push "${DST_ARM64}"

echo ">>> manifest list -> ${DST_MULTI}"
docker manifest rm "${DST_MULTI}" >/dev/null 2>&1 || true

docker manifest create --insecure "${INSECURE[@]}" "${DST_MULTI}" \
  --amend "${DST_AMD64}" \
  --amend "${DST_ARM64}"

docker manifest annotate "${DST_MULTI}" "${DST_AMD64}" --os linux --arch amd64
docker manifest annotate "${DST_MULTI}" "${DST_ARM64}" --os linux --arch arm64

docker manifest push "${INSECURE[@]}" "${DST_MULTI}"

echo "完成: ${DST_MULTI}（含 ${TAG_AMD64} / ${TAG_ARM64}）"
docker buildx imagetools inspect "${DST_MULTI}" 2>/dev/null || docker manifest inspect "${INSECURE[@]}" "${DST_MULTI}"
