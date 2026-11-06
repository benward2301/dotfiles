
fzf-history-widget() {
  local ctrl_r_height=$(( LINES * 60 / 100 ))
  (( ctrl_r_height > LINES - 2 )) && ctrl_r_height=$(( LINES - 2 ))
  local FZF_CTRL_R_OPTS="--height=~${ctrl_r_height}"
  local selected key
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases noglob nobash_rematch 2> /dev/null
  if zmodload -F zsh/parameter p:{commands,history} 2>/dev/null && (( ${+commands[perl]} )); then
    selected="$(printf '%s\t%s\000' "${(kv)history[@]}" |
      perl -0 -ne 'if (!$seen{(/^\s*[0-9]+\**\t(.*)/s, $1)}++) { s/\n/\n\t/g; print; }' |
      FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --read0 --expect=ctrl-o --bind 'space:put( )' --prompt='󰄾 ' --bind 'ctrl-y:execute-silent(echo {} | cut -f2- | sd \"\n\t\" \"\n\" | ucopy)+abort'") \
      FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
  else
    selected="$(fc -rl 1 | __fzf_exec_awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
      FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --expect=ctrl-o --bind 'space:put( )' --prompt='󰄾 ' --bind 'ctrl-y:execute-silent(echo {} | sed \"s/^[ \t]*[0-9]*\\**[ \t]*//\" | ucopy)+abort'") \
      FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
  fi
  local ret=$?
  key="${selected%%$'\n'*}"
  selected="${selected#*$'\n'}"
  if [ -n "$selected" ]; then
    if [[ $(__fzf_exec_awk '{print $1; exit}' <<< "$selected") =~ ^[1-9][0-9]* ]]; then
      BUFFER="${history[$MATCH]}"
      CURSOR=${#BUFFER}
    else
      LBUFFER="$selected"
    fi
  fi
  zle reset-prompt
  return $ret
}

zle -N fzf-history-widget
bindkey '^R' fzf-history-widget
