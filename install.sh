#!/usr/bin/env bash
#
# 将 create_ios_project.sh 安装为全局命令 iospc。
#
# 本地（仓库内）:
#   ./install.sh
#   ./install.sh --prefix ~/bin
#
# 远程（curl 一键安装，无需先 clone）:
#   curl -fsSL https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main/install.sh | bash
#
# 环境变量:
#   INSTALL_PREFIX   安装目录（默认: $HOME/.local/bin）
#   IOSPC_RAW_BASE   远程脚本所在 raw 目录（不含文件名，无末尾 /）
#                    默认: https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main
#

set -euo pipefail

INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/.local/bin}"

# 默认与仓库 origin 一致；自建 fork 时可导出 IOSPC_RAW_BASE 覆盖
IOSPC_RAW_BASE_DEFAULT="https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main"

SCRIPT_REF="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$SCRIPT_REF" ]]; then
  case "$SCRIPT_REF" in
    -|/dev/fd/*|/proc/self/fd/*)
      # curl ... | bash：以当前工作目录判断是否与 clone 同目录
      SCRIPT_DIR="$(pwd)"
      ;;
    *)
      if [[ -f "$SCRIPT_REF" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_REF")" && pwd)"
      fi
      ;;
  esac
fi

SOURCE_SCRIPT=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/create_ios_project.sh" ]]; then
  SOURCE_SCRIPT="$SCRIPT_DIR/create_ios_project.sh"
fi

usage() {
  cat <<EOF
用法: $(basename "${BASH_SOURCE[0]:-install.sh}") [--prefix <目录>]

将 create_ios_project.sh 安装为 <目录>/iospc 并赋予执行权限。

若当前目录旁没有 create_ios_project.sh（例如通过 curl 管道执行本脚本），
会从 GitHub raw 下载 create_ios_project.sh（可用环境变量 IOSPC_RAW_BASE 指定源）。

选项:
  -p, --prefix <目录>   安装目录（也可用环境变量 INSTALL_PREFIX）
  -h, --help            显示本说明

环境变量:
  INSTALL_PREFIX    默认 \$HOME/.local/bin
  IOSPC_RAW_BASE    远程目录 URL，默认:
                    $IOSPC_RAW_BASE_DEFAULT

默认安装目录: \$HOME/.local/bin
卸载: rm <安装目录>/iospc

curl 一键安装示例:
  curl -fsSL ${IOSPC_RAW_BASE_DEFAULT}/install.sh | bash
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prefix)
      [[ -n "${2:-}" ]] || { echo "错误: $1 需要目录参数" >&2; exit 1; }
      INSTALL_PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "错误: 未知选项: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

mkdir -p "$INSTALL_PREFIX"
TARGET="$INSTALL_PREFIX/iospc"
TMP=""
cleanup() { [[ -n "${TMP:-}" && -f "$TMP" ]] && rm -f "$TMP"; }
trap cleanup EXIT

if [[ -n "$SOURCE_SCRIPT" ]]; then
  cp -f "$SOURCE_SCRIPT" "$TARGET"
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "错误: 未找到 curl，无法从网络下载。请安装 curl，或进入本仓库目录后执行 ./install.sh（与 create_ios_project.sh 同目录）。" >&2
    exit 1
  fi
  BASE="${IOSPC_RAW_BASE:-$IOSPC_RAW_BASE_DEFAULT}"
  BASE="${BASE%/}"
  URL="$BASE/create_ios_project.sh"
  echo "正在下载: $URL" >&2
  TMP="$(mktemp "${TMPDIR:-/tmp}/iospc.XXXXXX")"
  if ! curl -fsSL "$URL" -o "$TMP"; then
    echo "错误: 下载失败。请检查网络，或设置 IOSPC_RAW_BASE 指向你的 fork/分支。" >&2
    exit 1
  fi
  cp -f "$TMP" "$TARGET"
fi

chmod +x "$TARGET"

echo "已安装: $TARGET"
echo ""

# 检查是否在 PATH 中
case ":${PATH:-}:" in
  *:"$INSTALL_PREFIX":*)
    echo "可直接运行: iospc --help"
    ;;
  *)
    echo "请将以下目录加入 PATH（若尚未加入）:"
    echo "  export PATH=\"$INSTALL_PREFIX:\$PATH\""
    echo ""
    echo "可写入 shell 配置文件（如 ~/.zshrc）后执行 source ~/.zshrc，再运行: iospc --help"
    ;;
esac
