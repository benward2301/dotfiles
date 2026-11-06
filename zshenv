export PATH="\
$HOME/go/bin:\
$HOME/.local/bin:\
$HOME/.local/share/mise/shims:\
$PATH"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgreprc"

export CLAUDE_CODE_FORCE_SYNC_OUTPUT=1
export CLAUDE_CODE_FORCE_STRIKETHROUGH=1

[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
