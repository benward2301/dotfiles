#!/bin/sh
set -eu

command -v sudo >/dev/null 2>&1 || {
  echo "sudo is missing. As root: pacman -S sudo git, add yourself to wheel," >&2
  echo "then run ./install.sh again as your own user." >&2
  exit 1
}

packages="curl sudo openssh zsh gcc less ex-vi-compat unzip zip fuse3"
packages="$packages networkmanager sddm keyd"
packages="$packages plasma-meta dolphin konsole wl-clipboard flatpak"

if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  sudo sed -i '/^#\[multilib\]/,/^#Include/{s/^#//}' /etc/pacman.conf
fi

sudo pacman -Syu --needed $packages

sudo systemctl enable NetworkManager.service sddm.service
