#!/bin/sh
set -eu

cd "$(dirname "$0")"

[ "$(id -u)" -ne 0 ] || {
  echo "run this as your own user, not root" >&2
  exit 1
}

. /etc/os-release
bootstrap=
for id in $ID ${ID_LIKE-}; do
  if [ -f "bootstrap/$id.sh" ]; then
    bootstrap=bootstrap/$id.sh
    break
  fi
done

if [ -n "$bootstrap" ]; then
  sh "$bootstrap"
else
  echo "no bootstrap for '$ID'" >&2
fi

if zsh=$(command -v zsh) && [ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "$zsh" ]; then
  chsh -s "$zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
export MISE_CONFIG_DIR="$PWD/mise"

git submodule update --init --recursive
command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.run | sh
mise install
mise exec -- dotbot -c install.conf.yaml

echo
echo "Setup finished."
if command -v keyd >/dev/null 2>&1 && ! cmp -s keyd/default.conf /etc/keyd/default.conf; then
  echo
  echo "keyd's config lives in /etc, so it is left for you to install:"
  echo "  sudo install -Dm644 $PWD/keyd/default.conf /etc/keyd/default.conf &&"
  echo "  sudo systemctl enable keyd && sudo systemctl restart keyd"
fi
if [ "${XDG_CURRENT_DESKTOP-}" != KDE ]; then
  echo
  echo "KDE settings can only be applied from inside a Plasma session. Reboot,"
  echo "log in to Plasma, then run ./install.sh again."
fi
