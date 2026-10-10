#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ask() {
  sleep 3
  echo "We were unable to successfully change the system language, but this does not prevent us from continuing to complete the script." >&2
  echo "This may result in subsequent Chinese text displaying abnormally." >&2
  echo "Note: The script is not in English" >&2
  echo "Continue? [Y/n]" >&2
  read -r answer
case "$answer" in
    ""|y|Y|yes|Yes|YES)
        echo "About to skip this step..." >&2
        exit 0
        ;;

    n|N|no|No|NO)
        echo "See you next time, meow" >&2
        exit 1
        ;;

    *)
        echo "You probably pressed the wrong button, meow, but still exited..." >&2
        exit 1
        ;;
esac
}

get_system_language() {
  sys_lang="$(locale | grep -E '^LANG=' | cut -d= -f2)"
  if [[ -z "$sys_lang" || "$sys_lang" == "C" || "$sys_lang" == "POSIX" ]]; then
    sys_lang="en_US"
  fi
  echo "${sys_lang%%_*}"
}

SYSTEM_LANGUAGE="$(get_system_language)"

if [[ "$SYSTEM_LANGUAGE" == "zh" ]]; then
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root." 2>&1
    ask
fi

sudo cp -p /etc/locale.conf "$SCRIPT_DIR"/../cache/locale.conf.backup
sudo cp -p /etc/locale.gen "$SCRIPT_DIR"/../cache/locale.gen.backup

if [[ ! -s "$SCRIPT_DIR"/../language/locale.conf || ! -s "$SCRIPT_DIR"/../language/locale.gen ]] ; then
  echo "File missing"
  ask
fi

sudo cp -f "$SCRIPT_DIR"/../language/locale.conf /etc/locale.conf
sudo cp -f "$SCRIPT_DIR"/../language/locale.gen /etc/locale.gen

if sudo locale-gen > /dev/null; then
  echo "Change the system language to Chinese." >&2
else
  echo "locale-gen failed" >&2
  sudo cp -pf "$SCRIPT_DIR"/../cache/locale.conf.backup /etc/locale.conf
  sudo cp -pf "$SCRIPT_DIR"/../cache/locale.gen.backup /etc/locale.gen
  sudo locale-gen > /dev/null
  ask
fi