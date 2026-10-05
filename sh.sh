#!/usr/bin/env bash

set -euo pipefail

# 第一次执行时要求输入密码
sudo -v

# 后台持续刷新 sudo 认证
(
    while true; do
        sudo -n -v
        sleep 60
    done
) &
SUDO_KEEPALIVE_PID=$!

# 脚本退出时停止刷新
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT


if sudo pacman -Syu --noconfirm ; then
    sudo pacman -S rate-mirrors --noconfirm --needed
else
    echo "更新失败喵~" >&2
    exit 1
fi
rate-mirrors --save=/tmp/mirrorlist arch && sudo mv /tmp/mirrorlist /etc/pacman.d/mirrorlist

sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[archlinuxcn]
Server = https://mirrors.cernet.edu.cn/archlinuxcn/$arch
EOF

if grep -qF '[archlinuxcn]' /etc/pacman.conf &&
   grep -qF 'Server = https://mirrors.cernet.edu.cn/archlinuxcn/$arch' /etc/pacman.conf; then
    echo "archlinuxcn 仓库添加成功"
else
    echo "错误：archlinuxcn 仓库添加失败" >&2
    exit 1
fi
if sudo pacman -Sy --noconfirm ; then
  sudo pacman -S archlinuxcn-keyring git yay --noconfirm --needed
else
  echo "下载失败喵~" >&2
  exit 1
fi

chmod +x ./resource/sh/*.sh
if ! TERMINAL="$("./resource/sh/get_terminal.sh")"; then
    echo "错误：系统中没有找到可用的终端模拟器。" >&2
    exit 1
fi
echo "启动 Steam 更新脚本..."
