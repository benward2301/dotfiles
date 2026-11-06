__fzf_recents_add() {
  printf '%s' "$2" |
    "${FZF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fzf}/lib/recents-add.sh" "$1"
}
