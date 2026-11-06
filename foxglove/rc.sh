. "${XDG_CONFIG_HOME:-$HOME/.config}/foxglove/foxglove.sh"

[ -f "$HOME/.local/share/nvim/foxglove.sh" ] && . "$HOME/.local/share/nvim/foxglove.sh"

export GLAMOUR_STYLE="${XDG_CONFIG_HOME:-$HOME/.config}/foxglove/glamour.json"
command -v glow >/dev/null && alias glow='glow -s $GLAMOUR_STYLE'
__palette_cache=$HOME/.local/share/foxglove/colorscheme.lua
if [ -f "$__palette_cache" ]; then
  __palette_dark=$(awk '/^  dark =/ { sub(/,$/, "", $3); print $3; exit }' "$__palette_cache")
  case $__palette_dark in
    true)  export COLORFGBG='15;0' ;;
    false) export COLORFGBG='0;15' ;;
  esac
  unset __palette_dark
fi
unset __palette_cache
