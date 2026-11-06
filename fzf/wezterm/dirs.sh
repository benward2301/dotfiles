#!/usr/bin/env zsh

set -e

target_pane_id="$1"
if [[ -z "$target_pane_id" ]]; then
  echo "Usage: wezterm/dirs.sh <target_pane_id>" >&2
  exit 1
fi

FZF_DIR="${FZF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fzf}"
source "$FZF_DIR/lib/recents.sh"

result=$(
  FZF_DEFAULT_COMMAND=${FZF_ALT_C_COMMAND:-} \
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --reverse --walker=dir,follow,hidden --scheme=path ${FZF_ALT_C_OPTS-} --height=100% -m" \
  FZF_DEFAULT_OPTS_FILE='' \
  fzf | while IFS= read -r item; do
    echo -n "${(q)item} "
  done
) || true

result="${result% }"

if [[ -n "$result" ]]; then
  __fzf_recents_add "alt-c" "$result"
  wezterm cli send-text --pane-id "$target_pane_id" --no-paste "$result"
fi
