#!/bin/bash

docker stop py_arm_amd64_crosscompile_arm64
docker rm py_arm_amd64_crosscompile_arm64
docker rm py_arm_amd64_sysroot
docker volume prune -a -f