#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "必须以 root 身份运行。"
    exit 1
fi

echo "开始镜像排序..."
sleep 2

sudo pacman -S rate-mirrors --noconfirm --needed

rate-mirrors --save=/tmp/mirrorlist arch && sudo mv /tmp/mirrorlist /etc/pacman.d/mirrorlist

echo "镜像排序成功"