export EDITOR=nvim

command -v mise >/dev/null && eval "$(mise activate zsh)"

if [[ -S "/run/user/$UID/keyring/.ssh" ]]; then
  export SSH_AUTH_SOCK="/run/user/$UID/keyring/.ssh"
elif [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
  if [[ ! -S "$SSH_AUTH_SOCK" ]] && command -v ssh-agent >/dev/null; then
    ssh-agent -a "$SSH_AUTH_SOCK" &>/dev/null
  fi
fi

setopt histignorealldups sharehistory appendhistory

bindkey -e

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

autoload -Uz compinit && compinit
autoload bashcompinit && bashcompinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
command -v dircolors >/dev/null && eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/foxglove/rc.sh" ]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/foxglove/rc.sh"
fi

if [ -f ~/.zsh_aliases ]; then
  . ~/.zsh_aliases
fi

if [[ -n "${WEZTERM_EXECUTABLE_DIR-}" && ":$PATH:" != *":$WEZTERM_EXECUTABLE_DIR:"* ]]; then
  export PATH="$PATH:$WEZTERM_EXECUTABLE_DIR"
fi

if [[ -n "${WEZTERM_PANE-}" && -f "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/rc.sh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/rc.sh"
fi

for dir in fzf zle eza; do
  [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/$dir/rc.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/$dir/rc.sh"
done

command -v starship >/dev/null && eval "$(starship init zsh)"

