#!/usr/bin/env bash

set -euo pipefail

# 本脚本用于导出当前工作空间 src 目录下的仓库信息到 script/source.repos
# 会递归扫描 src 下任意深度的 Git 仓库（例如 src/reference/foo），
# 保证 vcs import 时路径与当前布局一致。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SRC_DIR="${WS_DIR}/src"
OUTPUT_FILE="${SCRIPT_DIR}/source.repos"

if ! command -v vcs >/dev/null 2>&1; then
  echo "错误: 未找到 'vcs' 命令，请先在 ROS2 环境中安装/激活 vcstool (vcs)。" >&2
  exit 1
fi

if [ ! -d "${SRC_DIR}" ]; then
  echo "错误: 未找到 src 目录: ${SRC_DIR}" >&2
  exit 1
fi

cd "${WS_DIR}"

echo "导出 ${SRC_DIR} 中的仓库（含子目录）到 ${OUTPUT_FILE}..."

echo "repositories:" > "${OUTPUT_FILE}"

# 相对 SRC_DIR 的路径作为 .repos 键（与 vcs import 目标目录布局一致）
append_exported_repo() {
  local repo_root="$1"
  local rel="$2"
  local -a lines

  mapfile -t lines < <(vcs export "${repo_root}" 2>/dev/null | tail -n +2)
  if [ "${#lines[@]}" -eq 0 ]; then
    echo "  跳过(vcs export 无输出): ${rel}" >&2
    echo "  # 跳过(vcs export 无输出): ${rel}" >> "${OUTPUT_FILE}"
    return
  fi

  local first="${lines[0]}"
  if [[ "${first}" =~ ^[[:space:]]+[^:]+: ]]; then
    printf '  %s:\n' "${rel}" >> "${OUTPUT_FILE}"
    local i
    for ((i = 1; i < ${#lines[@]}; i++)); do
      printf '%s\n' "${lines[i]}" >> "${OUTPUT_FILE}"
    done
  else
    echo "  警告: 未识别的 vcs 输出首行 (${rel}): ${first}" >&2
    printf '%s\n' "${lines[@]}" >> "${OUTPUT_FILE}"
  fi
}

# 枚举所有 Git 根（.git 可为目录或 worktree 用的文件），按路径排序便于稳定对比
while IFS= read -r repo; do
  [ -n "${repo}" ] || continue
  [ -d "${repo}" ] || continue

  rel="$(realpath --relative-to="${SRC_DIR}" "${repo}" 2>/dev/null || true)"
  if [[ -z "${rel}" ]] || [[ "${rel}" == ../* ]]; then
    continue
  fi

  if ! git -C "${repo}" rev-parse --git-dir >/dev/null 2>&1; then
    continue
  fi

  if ! git -C "${repo}" remote get-url origin >/dev/null 2>&1; then
    echo "  跳过(无 origin 远程): ${rel}" >&2
    echo "  # 跳过(无 origin 远程): ${rel}" >> "${OUTPUT_FILE}"
    continue
  fi

  echo "  处理仓库: ${rel}"
  append_exported_repo "${repo}" "${rel}"
done < <(
  find "${SRC_DIR}" -name .git \( -type d -o -type f \) -print0 \
    | while IFS= read -r -d '' g; do dirname "${g}"; done \
    | sort -u
)

echo "导出完成，结果已写入: ${OUTPUT_FILE}"
echo "说明: 若存在「目录内嵌独立仓库」，vcs import 时顺序可能需要手动调整。" >&2
