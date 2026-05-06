#!/bin/bash

docker stop qilin_arm64_crosscompile
docker rm qilin_arm64_crosscompile
docker rm qilin_arm64_sysroot
docker volume prune -a -f