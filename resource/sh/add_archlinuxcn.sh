#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ask() {
  sleep 3
  echo "我们没能成功添加archlinuxcn，但这不影响继续完成脚本" >&2
  echo "我们会放弃部分应用的安装" >&2
  echo "继续吗？[Y/n]" >&2
  read -r answer
case "$answer" in
    ""|y|Y|yes|Yes|YES)
        echo "即将跳过本步骤..." >&2
        echo "False"
        ;;

    n|N|no|No|NO)
        echo "下次再见喵" >&2
        exit 1
        ;;

    *)
        echo "你应该是按错了喵，但依旧退出..." >&2
        exit 1
        ;;
esac
}

Arch_File="$SCRIPT_DIR/../pacman/arch_pacman.conf"
CachyOS_File="$SCRIPT_DIR/../pacman/cachyos_pacman.conf"

if [[ $EUID -ne 0 ]]; then
    echo "必须以 root 身份运行。" 2>&1
    echo ask
fi

if [[ -z "${Distribution:-}" ]]; then
    echo "没有收到 Distribution" 2>&1
    echo ask
fi

sudo cp -p /etc/pacman.conf "$SCRIPT_DIR"/../cache/pacman.conf.backup

case "$Distribution" in
  arch)
    if [[ -e "$Arch_File" ]]; then
      sudo cp -f "$Arch_File" /etc/pacman.conf
    else
      echo "文件：$Arch_File 丢失，请重新获取文件" 2>&1
      echo ask
    fi
    ;;
  cachyos)
    if [[ -e "$CachyOS_File" ]]; then
      sudo cp -f "$CachyOS_File" /etc/pacman.conf
    else
      echo "文件：$CachyOS_File 丢失，请重新获取文件" 2>&1
      echo ask
    fi
    ;;
  *)
    echo "请联系脚本作者，告诉他你是如何到这一步的..." 2>&1
    echo ask
    ;;
esac

if grep -qF '[archlinuxcn]' /etc/pacman.conf &&
   grep -qF 'Server = https://mirrors.cernet.edu.cn/archlinuxcn/$arch' /etc/pacman.conf; then
    if sudo pacman -Sy archlinuxcn-keyring --noconfirm > /dev/null; then
      echo "我们已经成功添加archlinuxcn" 2>&1
      echo "True"
    else
    echo "下载失败喵~" 2>&1
    echo ask
    fi
else
    echo "我们没有成功添加archlinuxcn，准备回退这次操作..." 2>&1
    sleep 3
    sudo cp -p "$SCRIPT_DIR"/../cache/pacman.conf.backup /etc/pacman.conf
    sudo pacman -Sy --noconfirm > /dev/null
    echo ask
fi