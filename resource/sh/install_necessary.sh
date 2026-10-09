#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$SCRIPT_DIR/../pacman/necessary.txt"

if [[ $EUID -ne 0 ]]; then
    echo "必须以 root 身份运行。" 2>&1
    exit 1
fi

if [[ ! -f "$PKGLIST" ]]; then
  echo "找不到包列表" >&2
  exit 1
fi


if grep -vE '^[[:space:]]*(#|$)' "$PKGLIST" | sudo pacman -S --needed --noconfirm -; then
  echo "必要包安装完成。"
else
  echo "必要包安装失败。" >&2
  exit 1
fi