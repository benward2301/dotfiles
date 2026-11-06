#!/usr/bin/env zsh

RECENTS_FILE="$HOME/.local/state/fzf-picker-recents"
RECENTS_MAX=10000

__fzf_recents_record() {
  local picker_name="$1" value="$2"
  value="${value#"${value%%[^[:space:]]*}"}"
  value="${value%"${value##*[^[:space:]]}"}"
  [[ -z "$value" || "$value" == "//eval "* ]] && return

  [[ "$value" == "~/"* ]] && value="$HOME/${value#"~/"}"
  [[ "$value" == "~" ]] && value="$HOME"
  local -a words=("${(z)value}")
  if (( ${#words} > 1 )); then
    local all_paths=true w
    for w in "${words[@]}"; do
      [[ -e "${(Q)w}" ]] || { all_paths=false; break }
    done
    if [[ "$all_paths" == true ]]; then
      local -a abs_paths=()
      for w in "${words[@]}"; do
        abs_paths+=("${${(Q)w}:a}")
      done
      value="${(j: :)abs_paths}"
    fi
  else
    local unquoted="${(Q)value}"
    if [[ -e "$unquoted" ]]; then
      value="${unquoted:a}"
    elif [[ -e "$value" ]]; then
      value="${value:a}"
    fi
  fi

  mkdir -p "${RECENTS_FILE:h}"
  if [[ "$picker_name" == "recents" && -f "$RECENTS_FILE" ]]; then
    local original=$(jq -r --arg v "$value" 'select(.value == $v) | .picker' "$RECENTS_FILE" 2>/dev/null | tail -1)
    [[ -n "$original" ]] && picker_name="$original"
  fi
  printf '%s\n' "$value" | jq -Rnc --arg p "$picker_name" \
    '{ts: (now | floor), picker: $p, value: input}' >> "$RECENTS_FILE"

  local count=$(wc -l < "$RECENTS_FILE" 2>/dev/null) || return
  (( count <= RECENTS_MAX )) && return
  local tmp=$(mktemp)
  tail -n "$RECENTS_MAX" "$RECENTS_FILE" > "$tmp" && mv "$tmp" "$RECENTS_FILE"
}

__fzf_recents_record "$1" "$(cat)"
