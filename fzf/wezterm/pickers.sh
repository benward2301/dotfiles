#!/usr/bin/env zsh

set -e

target_pane_id="$1"
if [[ -z "$target_pane_id" ]]; then
  echo "Usage: wezterm/pickers.sh <target_pane_id>" >&2
  exit 1
fi

FZF_DIR="${FZF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fzf}"
export __FZF_COMBINED_MRU_FILE="/tmp/fzf-wezterm-mru-$(id -u)"

source "$FZF_DIR/picker.sh"
source "$FZF_DIR/widgets/menu.sh"

selected=$(
  "$FZF_DIR/lua/combined_picker.lua" |
    fzf --height=100% --no-preview --ansi --delimiter='|' --with-nth=2 \
        --no-multi --tiebreak=begin,index
)
selected="${selected%%|*}"

if [[ -z "$selected" ]]; then
  exit 0
fi

__fzf_combined_mru_set "$selected"
stty sane 2>/dev/null || true
printf '\033[?1049l' 2>/dev/null  # Exit alternate screen buffer if active

if nvim -l "$FZF_DIR/lua/picker.lua" --exists "$selected" 2>/dev/null; then
  result=$(__fzf_lua_picker "$selected" | tr '\n' ' ' | sd ' $' '') || true
else
  result=$(eval "_fzf_$selected" | tr '\n' ' ' | sd ' $' '') || true
fi

if [[ -n "$result" ]]; then
  __fzf_recents_add "$selected" "$result"
  if [[ "$result" == "//eval "* ]]; then
    cmd="${result#//eval }"
    wezterm cli send-text --pane-id "$target_pane_id" --no-paste "$cmd"
    printf '\r' | wezterm cli send-text --pane-id "$target_pane_id" --no-paste
  else
    wezterm cli send-text --pane-id "$target_pane_id" --no-paste "$result"
  fi
fi
