#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ask() {
  sleep 3
  echo "我们没能成功排序镜像源，但这不影响继续完成脚本" >&2
  echo "这可能会增加下载时间" >&2
  echo "继续吗？[Y/n]" >&2
  read -r answer
case "$answer" in
    ""|y|Y|yes|Yes|YES)
        sudo cp -pf "$SCRIPT_DIR"/../cache/mirrorlist.backup /etc/pacman.d/mirrorlist
        sudo pacman -Sy --noconfirm> /dev/null >&2
        echo "即将跳过本步骤..." >&2
        exit 0
        ;;

    n|N|no|No|NO)
        sudo cp -pf "$SCRIPT_DIR"/../cache/mirrorlist.backup /etc/pacman.d/mirrorlist
        sudo pacman -Sy --noconfirm> /dev/null >&2
        echo "下次再见喵" >&2
        exit 1
        ;;

    *)
        sudo cp -pf "$SCRIPT_DIR"/../cache/mirrorlist.backup /etc/pacman.d/mirrorlist
        sudo pacman -Sy --noconfirm> /dev/null >&2
        echo "你应该是按错了喵，但依旧退出..." >&2
        exit 1
        ;;
esac
}

if [[ $EUID -ne 0 ]]; then
    echo "必须以 root 身份运行。" >&2
    ask
fi

echo "开始镜像排序，这可能需要时间..." >&2

sudo pacman -S rate-mirrors --noconfirm --needed > /dev/null

sudo cp -p /etc/pacman.d/mirrorlist "$SCRIPT_DIR"/../cache/mirrorlist.backup

set +e
rate-mirrors --save="$SCRIPT_DIR"/../cache/mirrorlist arch 2>&1 | grep --line-buffered "} ->"
SORT_MIRRORLIST_RESULT=${PIPESTATUS[0]}
set -e

if [[ $SORT_MIRRORLIST_RESULT -ne 0 ]]; then
    echo "rate-mirrors 执行失败" >&2
    ask
fi

if [[ ! -s "$SCRIPT_DIR"/../cache/mirrorlist ]]; then
    echo "mirrorlist 为空或不存在" >&2
    ask
fi

sudo cp "$SCRIPT_DIR"/../cache/mirrorlist /etc/pacman.d/mirrorlist

sudo pacman -Syu --noconfirm> /dev/null