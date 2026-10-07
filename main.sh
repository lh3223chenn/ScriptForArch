#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$SCRIPT_DIR"/resource/sh/*.sh

Distribution="$(bash "$SCRIPT_DIR/resource/sh/welcome.sh")"

echo "输入你的root密码，只需要输入一次就行..." >&2
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

sudo bash "$SCRIPT_DIR/resource/sh/update_system.sh"

sudo bash "$SCRIPT_DIR/resource/sh/sort_mirrorlist.sh"

sudo env Distribution="$Distribution" bash "$SCRIPT_DIR/resource/sh/add_archlinuxcn.sh"

GET_TERMINAL_RESULT="$(sudo bash "$SCRIPT_DIR/resource/sh/get_terminal.sh")"



trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT