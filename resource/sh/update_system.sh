#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "必须以 root 身份运行。" 2>&1
    exit 1
fi

echo "我们正在为您更新系统，请耐心等待..." 2>&1
sleep 3

if sudo pacman -Syu --noconfirm > /dev/null; then
    echo "感谢您的耐心，即将进入下一步..." 2>&1
else
    echo "更新失败喵~" 2>&1
    exit 1
fi