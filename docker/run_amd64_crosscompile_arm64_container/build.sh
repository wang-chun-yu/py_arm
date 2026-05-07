#!/usr/bin/env bash
set -e
export TARGETPLATFORM='linux/arm64'

source /sysroot/opt/ros/humble/setup.bash

if [ "$TARGETPLATFORM" = "linux/amd64" ]; then
    export TARGET_ARCH=x86_64
elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    export TARGET_ARCH=aarch64
else
    exit -1
fi

export TARGET_TRIPLE=$TARGET_ARCH-linux-gnu
export CC=/usr/bin/$TARGET_TRIPLE-gcc
export CXX=/usr/bin/$TARGET_TRIPLE-g++
export CROSS_COMPILE=/usr/bin/$TARGET_TRIPLE-
export SYSROOT=/sysroot
export INSTALL_PATH=
export PKG_CONFIG_DIR=""
export PKG_CONFIG_PATH="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig:${SYSROOT}/usr/lib/${TARGET_TRIPLE}/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT

export ROS2_IMAGE=${SYSROOT}/opt/ros/humble
export INSTALL_PATH=/home/chunyu/install

[ -e "$ROS2_IMAGE/local_setup.bash" ] && source $ROS2_IMAGE/local_setup.bash

if [ "$TARGETPLATFORM" = "linux/amd64" ]; then
    :
elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    :
else
    exit -1
fi

sudo mkdir -p $INSTALL_PATH
sudo chown -R 1000:1000 $INSTALL_PATH

# sysroot 内 ROS/ament 导出的 IMPORTED 库常为 /usr/lib/<triplet>/lib*.so；在 amd64 交叉机上该路径默认不存在，
# GNU make 会把其当作需更新的前提，报 “No rule to make target '/usr/lib/.../libfoo.so'”。
# 将主机同名路径指向 sysroot 下 triplet 目录（与 TARGET_TRIPLE 一致）。
# 优先 bind mount（整树一致）；在默认 Docker（无 CAP_SYS_ADMIN）下 mount 会失败，则回退为对
# $real 顶层逐项 ln -sfn 到 $marker（与 Walkerc_pro/build_arm.sh 白名单同思路，但自动覆盖目录内已有名项）。
qilin_link_host_triplet_libdir() {
  [ "$TARGETPLATFORM" = "linux/arm64" ] || return 0
  [ -n "${SYSROOT:-}" ] || return 0
  local marker="/usr/lib/${TARGET_TRIPLE}"
  local real="${SYSROOT}/usr/lib/${TARGET_TRIPLE}"
  [ -d "$real" ] || return 0
  if [ -L "$marker" ]; then
    sudo ln -sfn "$real" "$marker"
    return 0
  fi
  if [ -d "$marker" ]; then
    if sudo mountpoint -q "$marker" 2>/dev/null; then
      return 0
    fi
    if sudo mount --bind "$real" "$marker" 2>/dev/null; then
      return 0
    fi
    # 无 mount 权限时：为 sysroot  triplet 顶层每一项建指向 real 的同名 symlink
    local p
    while IFS= read -r -d '' p; do
      sudo ln -sfn "$p" "${marker}/$(basename "$p")"
    done < <(find "$real" -mindepth 1 -maxdepth 1 -print0)
    return 0
  fi
  sudo mkdir -p "$(dirname "$marker")"
  sudo ln -sfn "$real" "$marker"
}
qilin_link_host_triplet_libdir

# 交叉编 aarch64 时在 x86 上无法执行产物；gtest_discover_tests 会跑测试二进制，报
# ld-linux-aarch64.so.1 / binfmt 相关错误。关闭测试构建（与 Walkerc_pro/build_arm.sh 一致）。
colcon build \
    --install-base $INSTALL_PATH \
    --cmake-force-configure \
    --cmake-args \
        -DMIDDLEWARE_TYPE=ros2 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
        -DBUILD_TESTING=OFF \
        $CMAKE_ARGS \
        -DCMAKE_TOOLCHAIN_FILE="$(pwd)/././toolchain.cmake"

# 编译成功后，生成git信息文件
GIT_INFO_FILE="${INSTALL_PATH}/git_info"
SYSTEM_DIR="${HOME}/py_arm/src/system"

echo "正在收集 Git 仓库信息..."

# 清空并重新创建git_info文件
> "$GIT_INFO_FILE"

echo "==================================" >> "$GIT_INFO_FILE"
echo "Git 仓库信息" >> "$GIT_INFO_FILE"
echo "生成时间: $(date)" >> "$GIT_INFO_FILE"
echo "==================================" >> "$GIT_INFO_FILE"
echo "" >> "$GIT_INFO_FILE"

if [ -d "$SYSTEM_DIR" ]; then
    for repo in "$SYSTEM_DIR"/*/ ; do
        if [ -d "$repo" ]; then
            repo_name=$(basename "$repo")
            echo "-----------------------------------" >> "$GIT_INFO_FILE"
            echo "仓库: $repo_name" >> "$GIT_INFO_FILE"
            echo "路径: $repo" >> "$GIT_INFO_FILE"
            echo "-----------------------------------" >> "$GIT_INFO_FILE"
            
            if [ -d "${repo}.git" ]; then
                cd "$repo"
                
                # 记录最新的 commit 信息
                echo "" >> "$GIT_INFO_FILE"
                echo "最新 Commit:" >> "$GIT_INFO_FILE"
                git log -1 --pretty=format:"  Commit: %H%n  Author: %an <%ae>%n  Date:   %ad%n  Message: %s%n" >> "$GIT_INFO_FILE"
                echo "" >> "$GIT_INFO_FILE"
                
                # 记录当前分支
                echo "" >> "$GIT_INFO_FILE"
                echo "当前分支:" >> "$GIT_INFO_FILE"
                git branch --show-current >> "$GIT_INFO_FILE"
                echo "" >> "$GIT_INFO_FILE"
                
                # 记录 git status
                echo "Git Status:" >> "$GIT_INFO_FILE"
                git status >> "$GIT_INFO_FILE"
                echo "" >> "$GIT_INFO_FILE"
                
                cd - > /dev/null
            else
                echo "  (非 Git 仓库)" >> "$GIT_INFO_FILE"
                echo "" >> "$GIT_INFO_FILE"
            fi
        fi
    done
else
    echo "警告: 目录 $SYSTEM_DIR 不存在" >> "$GIT_INFO_FILE"
fi

echo "==================================" >> "$GIT_INFO_FILE"
echo "Git 信息已保存到: $GIT_INFO_FILE"

if [ "$TARGETPLATFORM" = "linux/amd64" ]; then
    :
elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    :
else
    exit -1
fi