#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$SCRIPT_DIR"/resource/sh/*.sh

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

DESKTOP_ENV="$(bash "$SCRIPT_DIR/resource/sh/get_desktop_env.sh")"

sudo bash "$SCRIPT_DIR"/resource/sh/change_language.sh

DISTRIBUTION="$(bash "$SCRIPT_DIR/resource/sh/welcome.sh")"

sudo bash "$SCRIPT_DIR/resource/sh/update_system.sh"

sudo bash "$SCRIPT_DIR/resource/sh/sort_mirrorlist.sh"

ENABLE_ARCHLINUXCN="$(sudo env DISTRIBUTION="$DISTRIBUTION" bash "$SCRIPT_DIR/resource/sh/add_archlinuxcn.sh")"

USED_TERMINAL="$(sudo bash "$SCRIPT_DIR/resource/sh/get_terminal.sh")"

sudo bash "$SCRIPT_DIR"/resource/sh/install.necessary.sh

trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT