typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=none
ZSH_HIGHLIGHT_STYLES[arg0]=fg=none
ZSH_HIGHLIGHT_STYLES[precommand]=fg=none
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
ZSH_HIGHLIGHT_STYLES[path_approx]=none
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=blue
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=blue
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=cyan
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=cyan
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=fg=green
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=green
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=green
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=magenta

zle_highlight=('paste:none')

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
command -v sheldon >/dev/null && eval "$(sheldon source 2>/dev/null)"

ZSH_AUTOSUGGEST_STRATEGY=history
bindkey '^[[Z' autosuggest-accept

ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(ai_generate_command\*)

autoload -Uz edit-command-line
zle -N edit-command-line

_fast_edit_command_line() {
  local VISUAL='nvim --cmd "lua vim.g.mini = true"'
  zle edit-command-line
}
zle -N _fast_edit_command_line
bindkey "^X^E" _fast_edit_command_line

clear-screen() {
  print -n '\e[3J\e[H\e[2J'
  zle reset-prompt
}
zle -N clear-screen
bindkey '^L' clear-screen

source "${XDG_CONFIG_HOME:-$HOME/.config}/zle/ai-shell.sh"
