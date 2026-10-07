#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR"/resource/sh/welcome.sh

echo "输入你的root密码，只需要输入一次就行..."
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

chmod +x "$SCRIPT_DIR"/resource/sh/*.sh

if UPDATE_SYSTEM_RESULT="$(sudo bash "$SCRIPT_DIR/resource/sh/update_system.sh")"; then
  echo "$UPDATE_SYSTEM_RESULT"
fi

if SORT_MIRRORLIST_RESULT="$(sudo bash "$SCRIPT_DIR/resource/sh/sort_mirrorlist.sh")"; then
  echo "$SORT_MIRRORLIST_RESULT"
fi

if ADD_ARCHLINUXCN_RESULT="$(sudo env Distribution="$Distribution" bash "$SCRIPT_DIR/resource/sh/add_archlinuxcn.sh")"; then
  echo "$ADD_ARCHLINUXCN_RESULT"
fi


if ! TERMINAL="$("$SCRIPT_DIR/resource/sh/get_terminal.sh")"; then
    echo "错误：系统中没有找到可用的终端模拟器。" >&2
    exit 1
fi
echo "启动 Steam 更新脚本..."
