# !/usr/bin/bash
set -e

source /opt/ros/humble/setup.bash

colcon build \
    --cmake-force-configure \
    --cmake-args \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
	-DMIDDLEWARE_TYPE=ros2 \
        -DBUILD_TESTING=0
