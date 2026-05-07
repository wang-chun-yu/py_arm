#!/bin/bash
# 运行registry镜像
docker run -d \
    --restart=unless-stopped \
    --name registry \
    -v ~/hard_disk_2/data/registry:/var/lib/registry \
    -p 5000:5000 \
    registry:2