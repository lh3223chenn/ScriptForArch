#!/usr/bin/env bash

if [[ $EUID -eq 0 ]]; then
    echo "脚本不能使用root直接运行" >&2
    echo "请运行\"./main.sh\"" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "我们需要先确认您的发行版..." >&2
Distribution="$("$SCRIPT_DIR/get_distribution.sh")"
case "$Distribution" in
  cachyos|arch)
    echo "你的系统是：$Distribution，可以使用这个脚本！" >&2
    ;;
  unknown)
    echo "这是个什么系统？" >&2
    exit 1
    ;;
  *)
    echo "我们暂时不支持 $Distribution" >&2
    exit 1
    ;;
esac

echo "你真的要使用这个脚本吗喵~[Y/n]" >&2
read -r answer
case "$answer" in
    ""|y|Y|yes|Yes|YES)
        echo "那么我们开始吧！" >&2
        echo "$Distribution"
        ;;

    n|N|no|No|NO)
        echo "下次再见喵" >&2
        exit 1
        ;;

    *)
        echo "你应该是按错了喵" >&2
        exit 1
        ;;
esac