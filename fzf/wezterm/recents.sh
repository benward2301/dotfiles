#!/usr/bin/env zsh

set -e

target_pane_id="$1"
if [[ -z "$target_pane_id" ]]; then
  echo "Usage: wezterm/recents.sh <target_pane_id>" >&2
  exit 1
fi

FZF_DIR="${FZF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fzf}"
source "$FZF_DIR/picker.sh"
source "$FZF_DIR/widgets/menu.sh"

result=$(__fzf_lua_picker "recents" | tr '\n' ' ' | sd ' $' '') || true

if [[ -n "$result" ]]; then
  wezterm cli send-text --pane-id "$target_pane_id" --no-paste "$result"
fi
