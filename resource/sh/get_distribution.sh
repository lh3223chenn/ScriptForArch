#!/usr/bin/env bash
set -euo pipefail

if [[ -r /etc/os-release ]]; then
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