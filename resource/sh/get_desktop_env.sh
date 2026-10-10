#!/usr/bin/env bash
set -uo pipefail

target_user() {
    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        printf '%s' "$SUDO_USER"
    else
        id -un
    fi
}

TARGET_USER="$(target_user)"
TARGET_UID="$(id -u "$TARGET_USER" 2>/dev/null || echo "")"
TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"

read_user_env() {
    local key="$1"
    [[ -z "$TARGET_UID" ]] && return 1
    command -v systemctl >/dev/null 2>&1 || return 1

    local runtime="/run/user/$TARGET_UID"
    [[ -d "$runtime" ]] || return 1

    runuser -u "$TARGET_USER" -- env \
        XDG_RUNTIME_DIR="$runtime" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
        systemctl --user show-environment 2>/dev/null |
        sed -n "s/^${key}=//p" | head -n1
}

get_env() {
    local key="$1"
    local cur="${!key:-}"
    if [[ -n "$cur" ]]; then
        printf '%s' "$cur"
        return 0
    fi
    read_user_env "$key"
}

read_loginctl() {
    command -v loginctl >/dev/null 2>&1 || return 1

    local sid
    sid="$(loginctl list-sessions --no-legend 2>/dev/null |
           awk -v u="$TARGET_USER" '$3==u {print $1; exit}')"
    [[ -z "$sid" ]] && return 1

    loginctl show-session "$sid" -p Type -p Desktop -p Active 2>/dev/null
}

detect_by_process() {
    local p proc name
    for p in \
        "gnome-shell:gnome" \
        "plasmashell:kde" \
        "xfce4-session:xfce" \
        "mate-session:mate" \
        "cinnamon:cinnamon" \
        "lxqt-session:lxqt" \
        "lxsession:lxde" \
        "budgie-desktop:budgie" \
        "dde-session:deepin" \
        "gnome-session:gnome" \
        "sway:sway" \
        "Hyprland:hyprland" \
        "i3:i3" \
        "openbox:openbox" \
        "bspwm:bspwm" \
        "awesome:awesome" \
        "xmonad:xmonad"
    do
        proc="${p%%:*}"
        name="${p##*:}"
        if pgrep -u "$TARGET_USER" -x "$proc" >/dev/null 2>&1; then
            printf '%s' "$name"
            return 0
        fi
    done
    return 1
}

normalize_de() {
    local raw="${1,,}"
    raw="${raw//:/ }"

    case "$raw" in
        *gnome*|*ubuntu*)   echo gnome ;;
        *kde*|*plasma*)     echo kde ;;
        *xfce*)             echo xfce ;;
        *lxqt*)             echo lxqt ;;
        *lxde*)             echo lxde ;;
        *mate*)             echo mate ;;
        *cinnamon*)         echo cinnamon ;;
        *budgie*)           echo budgie ;;
        *deepin*|*dde*)     echo deepin ;;
        *pantheon*)         echo pantheon ;;
        *sway*)             echo sway ;;
        *hyprland*)         echo hyprland ;;
        *i3*)               echo i3 ;;
        *openbox*)          echo openbox ;;
        *bspwm*)            echo bspwm ;;
        *awesome*)          echo awesome ;;
        *xmonad*)           echo xmonad ;;
        *cosmic*)           echo cosmic ;;
        *unity*)            echo unity ;;
        "")                 echo "" ;;
        *)                  echo "unknown:$raw" ;;
    esac
}

DE=""
SESSION_TYPE=""

if info="$(read_loginctl)"; then
    while IFS='=' read -r k v; do
        case "$k" in
            Type)    SESSION_TYPE="${v,,}" ;;
            Desktop) [[ -z "$DE" && -n "$v" ]] && DE="$(normalize_de "$v")" ;;
        esac
    done <<< "$info"
fi

if [[ -z "$DE" ]]; then
    for var in XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION; do
        val="$(get_env "$var")"
        if [[ -n "$val" ]]; then
            DE="$(normalize_de "$val")"
            [[ -n "$DE" ]] && break
        fi
    done
fi

if [[ -z "$DE" ]]; then
    DE="$(detect_by_process || true)"
fi

if [[ -z "$SESSION_TYPE" ]]; then
    if [[ -n "$(get_env WAYLAND_DISPLAY)" ]]; then
        SESSION_TYPE="wayland"
    elif [[ -n "$(get_env DISPLAY)" ]]; then
        SESSION_TYPE="x11"
    elif [[ "$DE" == "sway" || "$DE" == "hyprland" ]]; then
        SESSION_TYPE="wayland"
    fi
fi

if [[ -z "$DE" || "$DE" == unknown:* ]]; then
    if [[ -n "$SESSION_TYPE" ]]; then
        DE="graphical-unknown"
    else
        DE="none"
    fi
fi

printf '%s\n' "$DE"