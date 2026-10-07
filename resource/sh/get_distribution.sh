#!/usr/bin/env bash
# get_distro.sh —— 输出当前发行版名称（小写）
set -euo pipefail

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ -n "${ID:-}" ]]; then
        echo "${ID,,}"
        exit 0
    fi
    if [[ -n "${NAME:-}" ]]; then
        echo "${NAME,,}"
        exit 0
    fi
fi

echo "unknown"