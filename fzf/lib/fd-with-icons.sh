#!/bin/sh
mode=file
case " $* " in
  *' --type d '*|*' --type=d '*|*' -td '*|*' -t d '*) mode=dir ;;
esac
fd "$@" | "${FZF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fzf}/lib/add-icons.lua" "$mode"
