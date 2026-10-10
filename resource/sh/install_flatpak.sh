#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/../flathub/app.txt"

FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
MIRROR_URL="https://mirrors.cernet.edu.cn/flathub"

if [[ $EUID -ne 0 ]]; then
    echo "错误：请使用 sudo 运行本脚本。" >&2
    exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "错误：未安装 flatpak。" >&2
    exit 1
fi

if ! command -v runuser >/dev/null 2>&1; then
    echo "错误：找不到 runuser 命令。" >&2
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "错误：应用清单不存在：$FILE" >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-}"
if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
    echo "错误：无法识别发起 sudo 的普通用户。" >&2
    exit 1
fi

if ! id "$REAL_USER" >/dev/null 2>&1; then
    echo "错误：用户不存在：$REAL_USER" >&2
    exit 1
fi

REAL_UID="$(id -u "$REAL_USER")"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
RUNTIME_DIR="/run/user/$REAL_UID"

if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    echo "错误：无法获取用户主目录。" >&2
    exit 1
fi

as_root() { "$@"; }

as_user() {
    runuser -u "$REAL_USER" -- env \
        HOME="$REAL_HOME" \
        XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus" \
        "$@"
}

delete_system_flatpak() {
    if as_root flatpak remotes --system --columns=name 2>/dev/null |
        grep -Fxq 'flathub'; then
        if ! as_root flatpak remote-delete --system flathub; then
            echo "系统级 flathub 删除失败，跳过..." >&2
            return 0
        fi
    fi
}

delete_system_flatpak

if ! as_user flatpak remote-add --if-not-exists --user flathub "$FLATHUB_URL"; then
    echo "添加用户级 Flathub 失败，跳过安装流程。" >&2
    exit 0
fi

if ! as_user flatpak remote-modify --user flathub --url="$MIRROR_URL"; then
    echo "修改 Flathub 镜像地址失败，跳过安装流程。" >&2
    exit 0
fi

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="${raw_line%%#*}"
    line="$(printf '%s' "$line" |
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue

    read -r -a fields <<< "$line"
    if (( ${#fields[@]} == 1 )); then
        remote="flathub"
        app="${fields[0]}"
    elif (( ${#fields[@]} == 2 )); then
        remote="${fields[0]}"
        app="${fields[1]}"
    else
        echo "警告：清单格式错误，跳过：$line" >&2
        continue
    fi

    if as_user flatpak install --user -y "$remote" "$app"; then
        echo "安装成功：$remote $app" >&2
    else
        echo "安装失败：$remote $app" >&2
    fi
done < "$FILE"