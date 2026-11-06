_ai_strip_wrapping() {
  setopt local_options extended_glob
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  if [[ "$s" == '```'*$'\n'*$'\n```' ]]; then
    s="${s#\`\`\`[^$'\n']#$'\n'}"
    s="${s%$'\n'\`\`\`}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
  fi
  if [[ "$s" == '`'*'`' && "$s" != *$'\n'* ]]; then
    s="${s#\`}"
    s="${s%\`}"
  fi
  print -r -- "$s"
}
_ai_print_help() {
  POSTDISPLAY=' Enter a natural language instruction, a shell command, or both. Add Shift to include terminal scrollback as context.'
  region_highlight=("${#BUFFER} $((${#BUFFER} + ${#POSTDISPLAY})) fg=8")
}
_ai_generate_command() {
  local include_scrollback="$1"

  local original_buffer="$BUFFER"
  if [[ -z "$original_buffer" && -z "$include_scrollback" ]]; then
    _ai_print_help
    return 0
  fi

  local aichat_options=""
  local input="$original_buffer"
  if [[ "$original_buffer" == *" -- "* ]]; then
    aichat_options="${original_buffer%% -- *}"
    input="${original_buffer#* -- }"
  fi

  zle -I
  BUFFER=""
  CURSOR=0

  local request="$input"

  if [[ -n "$include_scrollback" ]]; then
    local scrollback=""
    if [[ -n "${WEZTERM_PANE-}" ]]; then
      scrollback=$(wezterm cli get-text --start-line -20 2>/dev/null |
        perl -pe 's/\e\[[\x20-\x3f]*[\x40-\x7e]//g; s/\e[\x40-\x5f]//g; s/\r//g' |
        awk '{ buf = buf sep $0; sep = "\n" } /[^[:space:]]/ { print buf; buf = ""; sep = "" }' |
        tail -n 20 | sd '\s+$' '')
    fi
    scrollback="${scrollback%$'\n'*}"
    request="$request

Terminal scrollback (last 20 lines):
\`\`\`
$scrollback
\`\`\`"
  fi

  request="$request

The input above may contain a natural language instruction, a shell command, or both (typically separated by a hash or some other conventional delimiter). If only a shell command is provided, assume it needs fixing, optimising or otherwise improving."

  local response_file=$(mktemp)
  if _ai_run_with_spinner "$response_file" "Crafting..." "$request" "$aichat_options"; then
    local command=$(_ai_strip_wrapping "$(<"$response_file")")
    if [[ -n "$command" ]]; then
      BUFFER="$command"
      CURSOR=${#BUFFER}
    else
      BUFFER="$original_buffer"
      CURSOR=${#BUFFER}
    fi
  else
    BUFFER="$original_buffer"
    CURSOR=${#BUFFER}
  fi
  rm -f "$response_file"
  zle reset-prompt
}

ai_generate_command() {
  _ai_generate_command
}

ai_generate_command_using_scrollback() {
  _ai_generate_command scrollback
}

_ai_run_with_spinner() {
  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

  local response_file="$1"
  local spinner_text="$2"
  local input="$3"
  local aichat_options="$4"

  local os_name="$(
    if [[ -r /etc/os-release ]]; then
      . /etc/os-release; echo "$PRETTY_NAME"
    elif command -v lsb_release >/dev/null 2>&1; then
      lsb_release -ds
    else
      uname
    fi
  )"
  local user_utils="$(for prog in rg fd jq yq sd; do command -v $prog >/dev/null 2>&1 && echo -n "$prog "; done; echo)"

  local request="$input

Operating system: $os_name
User utilities: $user_utils"

  local session_name=$(uuidgen | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')

  local -a aichat_cmd=(aichat --role shell -c --session "$session_name" --save-session)
  if [[ -n "$aichat_options" ]]; then
    aichat_cmd+=(${=aichat_options})
  fi
  aichat_cmd+=("$request")

  local interrupted=0
  trap 'interrupted=1' INT

  printf '\e[?25l\e[34m|\e[0m %s' "$spinner_text" >/dev/tty
  "${aichat_cmd[@]}" > "$response_file" 2>/dev/null &
  local pid=$!

  local -a frames=('|' '/' '-' '\')
  local i=0
  while kill -0 $pid 2>/dev/null && (( ! interrupted )); do
    printf '\r\e[34m%s\e[0m %s' "${frames[$((i++ % 4 + 1))]}" "$spinner_text" >/dev/tty
    sleep 0.1
  done

  if (( interrupted )); then
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
  else
    wait $pid
  fi
  local exit_code=$?

  trap - INT
  printf '\e[2K\r\e[?25h' >/dev/tty

  (( interrupted || exit_code > 128 )) && return 1
  return 0
}

zle -N ai_generate_command
zle -N ai_generate_command_using_scrollback
bindkey '\eo' ai_generate_command
bindkey '\eO' ai_generate_command_using_scrollback
