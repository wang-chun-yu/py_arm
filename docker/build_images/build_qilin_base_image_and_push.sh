#!/bin/bash
docker login ybx.ubtrobot.com -u ubh -p ubtubt123
docker pull ybx.ubtrobot.com/moby/buildkit:buildx-stable-1
docker tag ybx.ubtrobot.com/moby/buildkit:buildx-stable-1 moby/buildkit:buildx-stable-1
if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
  docker buildx create --use --bootstrap --name mybuilder --driver docker-container
else
  docker buildx use mybuilder
  docker buildx inspect --bootstrap
fi

tag=ybx.ubtrobot.com/runtime/qilin/system:qilin-ros2-humble-rk3588-v1.0.0

docker buildx build --network=host \
  --platform linux/arm64,linux/amd64 \
  -f ros2-humble-rk3588-qilin.Dockerfile \
  -t "$tag" \
  --push \
  .