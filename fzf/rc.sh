export FZF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fzf"

__fzf_zws=$'\xe2\x80\x8b'  # zero-width space; bytes, so a C locale can parse it

export FZF_DEFAULT_OPTS="
  --style=minimal
  --multi
  --height=40
  --bind 'tab:down'
  --bind 'shift-tab:up'
  --bind 'ctrl-p:toggle-up' --bind 'ctrl-n:toggle-down'
  --bind 'ctrl-s:jump'
  --bind 'jump-cancel:transform:[[ \$FZF_KEY = esc ]] && echo abort'
  --bind 'ctrl-q:toggle-all' --bind 'ctrl-alt-c:deselect-all'
  --bind 'ctrl-/:toggle-preview'
  --bind 'alt-;:abort'
  --bind 'ctrl-alt-j:preview-half-page-down' --bind 'ctrl-alt-k:preview-half-page-up'
  --bind 'ctrl-alt-f:page-down' --bind 'ctrl-alt-b:page-up'
  --bind 'ctrl-alt-d:page-down' --bind 'ctrl-alt-u:page-up'
  --bind 'ctrl-alt-a:preview-top' --bind 'ctrl-alt-e:preview-bottom'
  --bind 'alt-a:first' --bind 'alt-e:last'
  --bind 'change:first'
  --bind 'space:accept'
  --bind 'ctrl-y:execute-silent(cat {+f} | sd \"\n\" \" \" | ucopy)+abort'
  --layout=reverse
  --header-border=horizontal
  --gutter=' '
  --color=dark
  --color=fg:-1,fg+:$(foxglove palette text1),bg:-1,bg+:$(foxglove palette base2)
  --color=hl:$(foxglove highlight PmenuMatch.fg),hl+:$(foxglove highlight PmenuMatch.fg)
  --color=info:$(foxglove palette subtext1),footer:$(foxglove palette subtext1)
  --color=header:$(foxglove palette text2)
  --color=marker:$(foxglove palette magenta1)
  --color=pointer:$(foxglove palette red1):regular
  --color=prompt:$(foxglove palette cyan0),spinner:$(foxglove palette orange1)
  --color=border:$(foxglove palette base3)"
 
export FZF_CTRL_T_COMMAND="$FZF_DIR/lib/fd-with-icons.sh --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="
  --height=40
  --ansi
  --delimiter='\t' --with-nth=2 --accept-nth=1
  --info-command='case \"\$FZF_PROMPT\" in *'$__fzf_zws'*) printf \"󰋜 %s\" \"\$FZF_INFO\" ;; *) printf \"%s\" \"\$FZF_INFO\" ;; esac'
  --bind 'ctrl-o:execute-silent(cut -f1 {f} | $FZF_DIR/lib/recents-add.sh ctrl-t)+become(${EDITOR:-vi} {+1} < /dev/tty > /dev/tty)'
  --bind 'ctrl-x:execute-silent(cut -f1 {f} | $FZF_DIR/lib/recents-add.sh ctrl-t)+execute(${EDITOR:-vi} {+1} < /dev/tty > /dev/tty)'
  --bind 'alt-i:transform: [[ {fzf:prompt} == *'$__fzf_zws'* ]] \
      && echo \"reload($FZF_CTRL_T_COMMAND --no-ignore . ~)\" \
      || echo \"reload($FZF_CTRL_T_COMMAND --no-ignore)\"'
  --bind 'ctrl-t:reload($FZF_CTRL_T_COMMAND . ~)+change-prompt(> '$__fzf_zws')'
  --bind 'alt-r:transform: [[ {fzf:prompt} == *'$__fzf_zws'* ]] \
      && echo \"reload($FZF_CTRL_T_COMMAND . ~)\" \
      || echo \"reload($FZF_CTRL_T_COMMAND)\"'
  --preview='\$FZF_DIR/lib/preview.sh {1}'
  --bind 'ctrl-y:execute-silent(cut -f1 {+f} | while IFS= read -r f; do realpath \"\$f\"; done | sd \"\n\" \" \" | sd \" \$\" \"\" | tee >(\$FZF_DIR/lib/recents-add.sh ctrl-t) | ucopy)+abort'
"

export FZF_ALT_C_COMMAND="$FZF_DIR/lib/fd-with-icons.sh --type d --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="--height=40
  --ansi
  --scheme=history
  --tiebreak=length
  --delimiter='\t' --with-nth=2 --accept-nth=1
  --info-command='case \"\$FZF_PROMPT\" in *'$__fzf_zws'*) printf \"󰋜 %s\" \"\$FZF_INFO\" ;; *) printf \"%s\" \"\$FZF_INFO\" ;; esac'
  --bind 'alt-i:transform: [[ {fzf:prompt} == *'$__fzf_zws'* ]] \
      && echo \"reload($FZF_ALT_C_COMMAND --no-ignore --absolute-path . ~)\" \
      || echo \"reload($FZF_ALT_C_COMMAND --no-ignore)\"'
  --bind 'alt-c:reload($FZF_ALT_C_COMMAND --absolute-path . ~)+change-prompt(> '$__fzf_zws')'
  --bind 'alt-r:transform: [[ {fzf:prompt} == *'$__fzf_zws'* ]] \
      && echo \"reload($FZF_ALT_C_COMMAND --absolute-path . ~)\" \
      || echo \"reload($FZF_ALT_C_COMMAND)\"'
  --preview='\$FZF_DIR/lib/preview.sh {1}'
  --bind 'ctrl-y:execute-silent(cut -f1 {+f} | while IFS= read -r f; do realpath \"\$f\"; done | sd \"\n\" \" \" | sd \" \$\" \"\" | tee >(\$FZF_DIR/lib/recents-add.sh alt-c) | ucopy)+abort'
"

export FZF_COMPLETION_OPTS='--bind ctrl-o:accept'
command -v fzf >/dev/null || return 0

zstyle ':completion:*' fzf-completion-keybindings

eval "$(fzf --zsh)"
fzf-file-widget() {
  __fzf_combined_mru_set "ctrl-t"
  __fzf_picker_open "ctrl-t"
}

zle -N fzf-file-widget
bindkey '^t' fzf-file-widget

fzf-cd-widget() {
  local FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --height=$(( LINES - 2 < 40 ? LINES - 2 : 40 ))"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local out="$(
    FZF_DEFAULT_COMMAND=${FZF_ALT_C_COMMAND:-} \
    FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --walker=dir,follow,hidden --scheme=path" "${FZF_ALT_C_OPTS-} -m --expect=space,ctrl-o") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) < /dev/tty)"
  local key="${out%%$'\n'*}"
  local items="${out#*$'\n'}"
  if [[ -z "$items" ]]; then
    zle redisplay
    return 0
  fi
  __fzf_recents_add "alt-c" "$items"
  local -a dirs=("${(@f)items}")
  if [[ ( "$key" == "space" || "$key" == "ctrl-o" ) && ${#dirs} -eq 1 ]]; then
    zle push-line
    BUFFER="builtin cd -- ${(q)dirs[1]:a}"
    zle accept-line
  elif [[ "$key" != "space" && "$key" != "ctrl-o" ]]; then
    local result=""
    local item
    for item in "${dirs[@]}"; do
      result+="${(q)item} "
    done
    result="${result% }"
    if [[ -z "$LBUFFER" ]]; then
      RBUFFER=" ${result}$RBUFFER"
    else
      [[ "${LBUFFER: -1}" != " " ]] && LBUFFER="$LBUFFER "
      LBUFFER="$LBUFFER${result}"
    fi
  fi
  zle reset-prompt
  return 0
}
zle -N fzf-cd-widget

source "$FZF_DIR/widgets/history.sh"
source "$FZF_DIR/widgets/menu.sh"
if [[ "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" == *[Uu][Tt][Ff]* ]]; then
  source "$FZF_DIR/widgets/completion.sh"
fi

export FZF_NAVIGATOR_SHOW_HIDDEN=1
export FZF_NAVIGATOR_SHOW_IGNORED=1
export FZF_NAVIGATOR_HIDE_HELP=1
export FZF_NAVIGATOR_BINDINGS=";:go_home,ctrl-alt-h:toggle_hidden_files,alt-i:toggle_ignored_files,space:open,ctrl-x:open"
export FZF_NAVIGATOR_FILE_PREVIEW_COMMAND="$FZF_DIR/lib/preview.sh"
export FZF_NAVIGATOR_OPTS="--no-hscroll --bold"
[ -f "$FZF_DIR/navigator/fzf-navigator.sh" ] &&
  source "$FZF_DIR/navigator/fzf-navigator.sh"

