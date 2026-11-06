#!/usr/bin/env bash

ICONS="$FZF_DIR/lib/add-rg-icons.lua"

OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
          __f={1}; __f=${__f#* }
          printf "%s:%s" "$PWD/$__f" {2} | "$FZF_DIR/lib/recents-add.sh" ripgrep
          nvim "$__f" +{2} > /dev/tty
        else
          __qf=$(mktemp "${TMPDIR:-/tmp}/frg.XXXXXX")
          while IFS= read -r __line; do
            __line=${__line#* }
            printf "%s\n" "$__line" >> "$__qf"
            __f=${__line%%:*}; __l=${__line#*:}; __l=${__l%%:*}
            printf "%s:%s" "$PWD/$__f" "$__l" | "$FZF_DIR/lib/recents-add.sh" ripgrep
          done < {+f}
          nvim +cw -q "$__qf" > /dev/tty
          rm -f "$__qf"
        fi'

trap '' INT

frg_shquote() {
  local out="" arg
  for arg in "$@"; do
    arg=${arg//\'/\'\\\'\'}
    out="$out '$arg'"
  done
  printf '%s' "$out"
}

rg --quiet "$@" 2>/dev/null
exit_code=$?

if [[ $exit_code -eq 2 ]]; then
  RG_CMD="rg --line-number --color=always --smart-case$(frg_shquote "$@")"
  RELOAD="reload:q={q}; { if [[ \"\$q\" == *\" -- \"* ]]; then setopt shwordsplit noglob 2>/dev/null || set -f; $RG_CMD \${q%% -- *} -- \"\${q#* -- }\" 2>&1 || :; else $RG_CMD \"\$q\" 2>&1 || :; fi; } | \"\$FZF_DIR/lib/add-rg-icons.lua\""
  IGLOB='q=$FZF_QUERY; if [[ "$q" == *" -- "* ]]; then r="beginning-of-line+put(--iglob  )+beginning-of-line"; else r="beginning-of-line+put(--iglob  -- )+beginning-of-line"; fi; for ((i=0;i<8;i++)); do r+=+forward-char; done; printf %s "$r"'
  NO_IGNORE='q=$FZF_QUERY; if [[ "$q" == *--no-ignore* ]]; then echo nop; elif [[ "$q" == *" -- "* ]]; then echo "beginning-of-line+put(--no-ignore )+end-of-line"; else echo "beginning-of-line+put(--no-ignore -- )+end-of-line"; fi'

  raw_output=$(FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind 'space:put( )' --prompt='󰄾 '" \
  fzf --disabled \
      --height=-2 \
      --ansi \
      --multi \
      --bind "start:$RELOAD" --bind "change:$RELOAD" \
      --bind "alt-r:$RELOAD" \
      --bind "ctrl-g:transform:$IGLOB" \
      --bind "alt-i:transform:$NO_IGNORE" \
      --bind "ctrl-o:become:$OPENER" \
      --bind "ctrl-x:execute:$OPENER" --bind "ctrl-x:+$RELOAD" \
      --bind "ctrl-y:execute-silent(printf '%s\n' {+} | awk -F: -v pwd=\"\$PWD\" 'NR>1{printf \"\\n\"} {sub(/^[^ ]* /, \"\"); printf \"%s/%s:%s\", pwd, \$1, \$2}' | sd '\n' ' ' | tee >($FZF_DIR/lib/recents-add.sh ripgrep) | ucopy)+abort" \
      --delimiter : \
      --preview 'f={1}; bat --number --color=always --highlight-line {2} -- "${f#* }"' \
      --preview-window 'down,~4,+{2}+4/3')

  [[ -z "$raw_output" ]] && exit
  printf '%s\n' "$raw_output" | awk -F: '{sub(/^[^ ]* /, ""); k=$1":"$2; if (!seen[k]++) print k}'
else
  RG_STATIC="rg --line-number --color=always --smart-case$(frg_shquote "$@") | \"$ICONS\""
  rg --line-number --color=always --smart-case "$@" | "$ICONS" |
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind 'space:put( )' --prompt='󰄾 '" \
  fzf \
      --ansi \
      --height=-2 \
      --multi \
      --bind "alt-r:reload($RG_STATIC)" \
      --bind "ctrl-o:become:$OPENER" \
      --bind "ctrl-x:execute:$OPENER" \
      --bind "ctrl-y:execute-silent(printf '%s\n' {+} | awk -F: -v pwd=\"\$PWD\" 'NR>1{printf \"\\n\"} {sub(/^[^ ]* /, \"\"); printf \"%s/%s:%s\", pwd, \$1, \$2}' | tee >($FZF_DIR/lib/recents-add.sh ripgrep) | ucopy)+abort" \
      --delimiter : \
      --preview 'f={1}; bat --number --color=always --highlight-line {2} -- "${f#* }"' \
      --preview-window 'down,~4,+{2}+4/3' |
  awk -F: '{sub(/^[^ ]* /, ""); k=$1":"$2; if (!seen[k]++) print k}'
fi
