source "$FZF_DIR/picker.sh"
source "$FZF_DIR/lib/shell-pickers.sh"
source "$FZF_DIR/lib/mru.sh"
source "$FZF_DIR/lib/recents.sh"
__fzf_dispatch_result() {
  local result="$1" smart_cursor="$2"
  [[ -z "$result" ]] && return 1
  if [[ "$result" == "//eval "* ]]; then
    LBUFFER="${result#//eval }"
    RBUFFER=""
    zle accept-line
  elif [[ "$result" == export\ * ]]; then
    if [[ -z "$LBUFFER" && "$smart_cursor" != "false" ]]; then
      RBUFFER="${result}$RBUFFER"
    else
      [[ "${LBUFFER: -1}" != " " && -n "$LBUFFER" ]] && LBUFFER="$LBUFFER "
      LBUFFER="$LBUFFER${result}"
    fi
  else
    __fzf_insert_to_buffer "$result" "$smart_cursor"
  fi
}
__fzf_combined_picker() {
  local input_script="$FZF_DIR/lua/combined_picker.lua"

  local picker_height=$(( LINES - 2 < 40 ? LINES - 2 : 40 ))

  local selected
  selected=$(
    "$input_script" |
    fzf --height=$picker_height --ansi --delimiter='|' --with-nth=2 --no-preview \
        --no-multi --tiebreak=begin,index \
        --bind 'enter:accept' \
        --bind "ctrl-r:reload($input_script 2>/dev/null)" \
        --bind 'ctrl-y:execute-silent(echo {} | cut -d"|" -f1 | ucopy)+abort'
  )

  [[ -z "$selected" ]] && { zle reset-prompt; return; }

  local item_name="${selected%%|*}"
  __fzf_combined_mru_set "$item_name"
  __fzf_picker_open "$item_name"
}

zle -N __fzf_combined_picker
bindkey '^[s' __fzf_combined_picker
__fzf_picker_open() {
  local picker="$1"; shift
  zle autosuggest-clear 2>/dev/null
  zle reset-prompt

  local out
  out=$("_fzf_$picker" "$@" | tr '\n' ' ' | sd ' $' '')

  if [[ -n "$out" ]]; then
    __fzf_recents_add "$picker" "$out"
    local smart_cursor=$(__fzf_lua_picker_config "$picker" "smart_cursor")
    __fzf_dispatch_result "$out" "$smart_cursor"
    __fzf_combined_mru_set "$picker"
  fi
  zle reset-prompt
}
__fzf_prefix_local_execs() {
  local -a words out
  local w unq
  words=(${(z)1})
  for w in "${words[@]}"; do
    unq=${(Q)w}
    if [[ "$unq" != */* && -f "$unq" && -x "$unq" ]]; then
      unq="./$unq"
      out+=("${(q)unq}")
    else
      out+=("$w")
    fi
  done
  print -r -- "${(j: :)out}"
}
__fzf_insert_to_buffer() {
  local result="$1"
  local smart_cursor="${2:-true}"
  [[ -n "$result" ]] && result=$(__fzf_prefix_local_execs "$result")
  if [[ -n "$result" ]]; then
    if [[ -z "$LBUFFER" && "$smart_cursor" != "false" ]]; then
      RBUFFER=" ${result}$RBUFFER"
    else
      [[ "${LBUFFER: -1}" != " " && -n "$LBUFFER" ]] && LBUFFER="$LBUFFER "
      LBUFFER="$LBUFFER${result} "
      CURSOR=${#LBUFFER}
    fi
  fi
}
__fzf_widget() {
  local picker_name="${1#_fzf_}"
  __fzf_combined_mru_set "$picker_name"
  __fzf_picker_open "$picker_name"
}
__fzf_git_status_widget()   { __fzf_widget _fzf_git_status; }
__fzf_git_log_widget()      { __fzf_widget _fzf_git_log; }
__fzf_git_branches_widget() { __fzf_widget _fzf_git_branches; }
__fzf_git_worktrees_widget(){ __fzf_widget _fzf_git_worktrees; }
__fzf_atch_sessions_widget() { __fzf_widget _fzf_atch_sessions; }
__fzf_recents_widget() { __fzf_widget _fzf_recents; }
__fzf_just_commands_widget() { __fzf_widget _fzf_just_commands; }

__fzf_ripgrep_widget() {
  __fzf_combined_mru_set "ripgrep"
  local buffer="$LBUFFER$RBUFFER"
  if [[ "$buffer" == rg\ * ]]; then
    __fzf_picker_open ripgrep ${buffer#rg }
  else
    __fzf_picker_open ripgrep
  fi
}

zle -N __fzf_git_status_widget
zle -N __fzf_git_log_widget
zle -N __fzf_git_branches_widget
zle -N __fzf_ripgrep_widget
zle -N __fzf_git_worktrees_widget
zle -N __fzf_atch_sessions_widget
zle -N __fzf_recents_widget
zle -N __fzf_just_commands_widget

bindkey '^g^m' __fzf_git_status_widget
bindkey '^g^l' __fzf_git_log_widget
bindkey '^g^b' __fzf_git_branches_widget
bindkey '^g^r' __fzf_ripgrep_widget
bindkey '^g^w' __fzf_git_worktrees_widget
bindkey '^g^a' __fzf_atch_sessions_widget
bindkey '^g^j' __fzf_just_commands_widget
bindkey '^[e' __fzf_recents_widget
