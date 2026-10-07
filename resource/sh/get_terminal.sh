#!/usr/bin/env bash

# 按优先级检测已有终端模拟器
if command -v alacritty >/dev/null 2>&1; then
    echo "alacritty"
    exit 0
fi

if command -v konsole >/dev/null 2>&1; then
    echo "konsole"
    exit 0
fi

if command -v gnome-terminal >/dev/null 2>&1; then
    echo "gnome-terminal"
    exit 0
fi

if command -v kitty >/dev/null 2>&1; then
    echo "kitty"
    exit 0
fi

if command -v xfce4-terminal >/dev/null 2>&1; then
    echo "xfce4-terminal"
    exit 0
fi

if command -v xterm >/dev/null 2>&1; then
    echo "xterm"
    exit 0
fi


# 没有找到终端
echo "未检测到可用的终端模拟器。" >&2
echo "是否安装 Alacritty？[Y/n]" >&2

read -r answer

case "$answer" in
    ""|y|Y|yes|Yes|YES)
        echo "正在安装 Alacritty..." >&2

        if ! sudo pacman -S alacritty --needed --noconfirm > /dev/null; then
            echo "错误：Alacritty 安装失败。" >&2
            exit 1
        fi
        ;;

    n|N|no|No|NO)
        echo "已取消安装。" >&2
        exit 1
        ;;

    *)
        echo "无效选择，已取消。" >&2
        exit 1
        ;;
esac


# 验证安装结果
if command -v alacritty >/dev/null 2>&1; then
    echo "Alacritty 安装成功。" >&2
    echo "alacritty"
    exit 0
fi

echo "我们没有成功下载任何终端软件..." 2>&1
echo "null"
exit 1

