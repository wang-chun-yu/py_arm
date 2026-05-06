# Qilin RK3588（aarch64）交叉编译 toolchain
# 环境：docker compose qilin_arm64_crosscompile（ubuntu:22.04-crosscompile）+ arm64_sysroot 卷挂载 /sysroot
# 使用：容器内 source /sysroot/opt/ros/humble/setup.bash 后执行 build.sh（会导出 CROSS_COMPILE、SYSROOT、ROS2_IMAGE 等）

cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)

if(NOT "$ENV{TARGET_ARCH}" STREQUAL "")
  set(CMAKE_SYSTEM_PROCESSOR "$ENV{TARGET_ARCH}")
elseif("$ENV{TARGETPLATFORM}" STREQUAL "linux/arm64")
  set(CMAKE_SYSTEM_PROCESSOR aarch64)
else()
  set(CMAKE_SYSTEM_PROCESSOR "$ENV{TARGET_ARCH}")
endif()

set(CMAKE_C_COMPILER "$ENV{CROSS_COMPILE}gcc")
set(CMAKE_CXX_COMPILER "$ENV{CROSS_COMPILE}g++")
set(CMAKE_SYSROOT "$ENV{SYSROOT}")

set(_qilin_find_root "$ENV{SYSROOT}")
if(NOT "$ENV{INSTALL_PATH}" STREQUAL "")
  list(APPEND _qilin_find_root "$ENV{INSTALL_PATH}")
endif()
if(NOT "$ENV{UBT_3RD_IMAGE}" STREQUAL "")
  list(APPEND _qilin_find_root "$ENV{UBT_3RD_IMAGE}")
endif()
if(NOT "$ENV{ROSA_IMAGE}" STREQUAL "")
  list(APPEND _qilin_find_root "$ENV{ROSA_IMAGE}")
endif()
set(CMAKE_FIND_ROOT_PATH ${_qilin_find_root})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

if(DEFINED ENV{SYSTEM_TAG})
  if("$ENV{SYSTEM_TAG}" STREQUAL "orin-8.5.2")
    set(CMAKE_CUDA_COMPILER "/usr/local/cuda-11.4/bin/nvcc")
    set(CMAKE_CUDA_FLAGS
      "-ccbin ${CMAKE_CXX_COMPILER} -Xcompiler -fPIC -I${CMAKE_SYSROOT}/usr/local/cuda-11.4/include -L${CMAKE_SYSROOT}/usr/local/cuda-11.4/lib64"
    )
  elseif("$ENV{SYSTEM_TAG}" STREQUAL "orin-8.6.2")
    set(CMAKE_CUDA_COMPILER "/usr/local/cuda-12.2/bin/nvcc")
    set(CMAKE_CUDA_FLAGS
      "-ccbin ${CMAKE_CXX_COMPILER} -Xcompiler -fPIC -I${CMAKE_SYSROOT}/usr/local/cuda-12.2/include -L${CMAKE_SYSROOT}/usr/local/cuda-12.2/lib64"
    )
  endif()
endif()

set(THREADS_PTHREAD_ARG
  "0"
  CACHE STRING
  "Result from TRY_RUN"
  FORCE
)

if("$ENV{TARGETPLATFORM}" STREQUAL "linux/arm64")
  if(NOT "$ENV{ROS2_IMAGE}" STREQUAL "")
    list(APPEND CMAKE_PREFIX_PATH "$ENV{ROS2_IMAGE}")
  endif()
endif()
