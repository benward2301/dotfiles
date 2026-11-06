__FZF_PICKER_LUA="$FZF_DIR/lua/picker.lua"
__fzf_lua_picker_config() {
  local picker_name="$1" field="$2" default="${3:-}"
  local value
  value=$(nvim -l "$__FZF_PICKER_LUA" --meta "$picker_name" 2>/dev/null | jq -r ".${field}" 2>/dev/null)
  [[ -z "$value" || "$value" == "null" ]] && value="$default"
  printf '%s' "$value"
}
__fzf_lua_generate_functions() {
  local picker_name
  while IFS= read -r picker_name; do
    [[ -z "$picker_name" ]] && continue
    eval "_fzf_${picker_name}() { __fzf_lua_picker '$picker_name' \"\$@\"; }"
  done < <(nvim -l "$__FZF_PICKER_LUA" --list 2>/dev/null)
  return 0
}
__fzf_lua_picker() {
  local picker_name="$1"
  shift
  local -a extra_fzf_args=("$@")
  local config
  config=$(nvim -l "$__FZF_PICKER_LUA" --meta "$picker_name" 2>/dev/null)
  [[ -z "$config" ]] && return 1

  local cmd=$(printf '%s' "$config" | jq -r '.command // ""')
  local format=$(printf '%s' "$config" | jq -r '.format // ""')
  local shell_quote=$(printf '%s' "$config" | jq -r '.shell_quote // false')
  local has_input=$(printf '%s' "$config" | jq -r '.has_input // false')
  local has_preview=$(printf '%s' "$config" | jq -r '.has_preview // false')
  local has_output=$(printf '%s' "$config" | jq -r '.has_output // false')
  local has_copy=$(printf '%s' "$config" | jq -r '.has_copy // false')
  local output_shell=$(printf '%s' "$config" | jq -r '.output // ""')

  local -a fzf_args=()
  local has_fields=false
  local i

  local fields_count=$(printf '%s' "$config" | jq -r '.fields_count // 0')
  [[ "$fields_count" -gt 0 && "$format" == "json" ]] && has_fields=true
  if [[ "$has_input" == "true" ]]; then
    cmd="nvim -l '$__FZF_PICKER_LUA' --run '$picker_name' 2>/dev/null"
    [[ "$has_fields" == true ]] && fzf_args+=(--delimiter=$'\t' --with-nth=2 --ansi)
  elif [[ "$has_fields" == true ]]; then
    cmd="$cmd | nvim -l '$__FZF_PICKER_LUA' --format '$picker_name' 2>/dev/null"
    fzf_args+=(--delimiter=$'\t' --with-nth=2 --ansi)
  fi
  fzf_args+=(--bind "alt-r:reload($cmd)")
  local preview=""
  if [[ "$has_preview" == "true" ]]; then
    if [[ "$format" == "json" ]]; then
      preview="nvim -l '$__FZF_PICKER_LUA' --preview '$picker_name' {1} 2>/dev/null"
    else
      preview="nvim -l '$__FZF_PICKER_LUA' --preview '$picker_name' {} 2>/dev/null"
    fi
    fzf_args+=(--preview "$preview")
    fzf_args+=(--preview-window=nohidden)
  else
    fzf_args+=(--preview-window=hidden)
  fi
  local opt_key opt_type opt_value
  local options_keys=$(printf '%s' "$config" | jq -r '.options | keys? | .[]? // empty' || true)
  [[ -n "$options_keys" ]] && while IFS= read -r opt_key; do
    [[ -z "$opt_key" ]] && continue
    opt_type=$(printf '%s' "$config" | jq -r ".options.\"$opt_key\" | type") || opt_type=""
    opt_value=$(printf '%s' "$config" | jq -r ".options.\"$opt_key\"") || opt_value=""

    case "$opt_type" in
      "boolean")
        [[ "$opt_value" == "true" ]] && fzf_args+=("--$opt_key")
        ;;
      "array")
        while IFS= read -r item; do
          [[ -n "$item" ]] && fzf_args+=("--$opt_key" "$item")
        done < <(printf '%s' "$config" | jq -r ".options.\"$opt_key\"[]" || true)
        ;;
      *)
        [[ -n "$opt_value" && "$opt_value" != "null" ]] && fzf_args+=("--$opt_key" "$opt_value")
        ;;
    esac
  done <<< "$options_keys" || true
  local no_space_accept=$(printf '%s' "$config" | jq -r '.no_space_accept // false')
  if [[ "$no_space_accept" == "true" ]]; then
    fzf_args+=(--bind 'space:put( )' --prompt '󰄾 ')
  fi
  local recents_add_cmd
  if [[ "$has_fields" == true && "$has_output" == true ]]; then
    recents_add_cmd="printf '%s' {1} | nvim -l '$__FZF_PICKER_LUA' --apply '$picker_name' output 2>/dev/null | '$FZF_DIR/lib/recents-add.sh' '$picker_name'"
  elif [[ "$has_fields" == true ]]; then
    recents_add_cmd="cut -f1 {f} | '$FZF_DIR/lib/recents-add.sh' '$picker_name'"
  elif [[ "$has_output" == true && "$format" == "json" ]]; then
    recents_add_cmd="printf '%s' {1} | nvim -l '$__FZF_PICKER_LUA' --apply '$picker_name' output 2>/dev/null | '$FZF_DIR/lib/recents-add.sh' '$picker_name'"
  else
    recents_add_cmd="printf '%s' {} | '$FZF_DIR/lib/recents-add.sh' '$picker_name'"
  fi
  for ((i=0; i<${#fzf_args[@]}; i++)); do
    if [[ "${fzf_args[$i]}" == "--bind" ]]; then
      local bind_val="${fzf_args[$((i+1))]}"
      if [[ "$bind_val" == ctrl-o:* || "$bind_val" == ctrl-x:* ]]; then
        local bind_key="${bind_val%%:*}"
        local bind_action="${bind_val#*:}"
        fzf_args[$((i+1))]="${bind_key}:execute-silent($recents_add_cmd)+${bind_action}"
      fi
    fi
  done
  local recents_tee="tee >('$FZF_DIR/lib/recents-add.sh' '$picker_name')"
  local copy_cmd
  if [[ "$format" == "json" && ( "$has_copy" == true || "$has_output" == true ) ]]; then
    if [[ "$shell_quote" == "true" ]]; then
      copy_cmd="cat {+f} | awk -F'\\t' '{print \$1}' | nvim -l '$__FZF_PICKER_LUA' --apply '$picker_name' copy --print0 2>/dev/null | while IFS= read -r -d '' val; do [[ -n \"\$val\" ]] && printf '%q ' \"\$val\"; done | sd ' \$' '' | $recents_tee | ucopy"
    else
      copy_cmd="cat {+f} | awk -F'\\t' '{print \$1}' | nvim -l '$__FZF_PICKER_LUA' --apply '$picker_name' copy 2>/dev/null | sd '\\n' ' ' | sd ' \$' '' | $recents_tee | ucopy"
    fi
  elif [[ "$format" != "json" && -n "$output_shell" ]]; then
    copy_cmd="cat {+f} | $output_shell | sd '\\n' ' ' | sd ' \$' '' | $recents_tee | ucopy"
  else
    if [[ "$shell_quote" == "true" ]]; then
      copy_cmd="cat {+f} | while IFS= read -r l; do [[ -n \"\$l\" ]] && printf '%q ' \"\$l\"; done | sd ' \$' '' | $recents_tee | ucopy"
    else
      copy_cmd="cat {+f} | sd '\n' ' ' | sd ' \$' '' | $recents_tee | ucopy"
    fi
  fi
  fzf_args+=(--bind "ctrl-y:execute-silent($copy_cmd)+abort")
  local eval_keys=$(printf '%s' "$config" | jq -r '.eval | keys? | .[]? // empty' || true)
  [[ -n "$eval_keys" ]] && while IFS= read -r eval_key; do
    [[ -z "$eval_key" ]] && continue
    fzf_args+=(--bind "${eval_key}:become(echo //eval:${eval_key}; cut -f1 {+f} | head -1)")
  done <<< "$eval_keys"
  for ((i=0; i<${#fzf_args[@]}; i++)); do
    if [[ "${fzf_args[$i]}" == "--bind" && -n "${fzf_args[$((i+1))]}" ]]; then
      fzf_args[$((i+1))]="${fzf_args[$((i+1))]//\{reload\}/$cmd}"
    fi
  done
  stty -inlcr -icrnl -ixon < /dev/tty
  local raw_output
  raw_output=$(eval "$cmd" | fzf "${fzf_args[@]}" ${extra_fzf_args[@]+"${extra_fzf_args[@]}"})

  local result
  if [[ "$raw_output" == //eval:* ]]; then
    local eval_key="${raw_output%%$'\n'*}"
    eval_key="${eval_key#//eval:}"
    local json="${raw_output#*$'\n'}"
    local eval_cmd=$(printf '%s' "$config" | jq -r ".eval.\"${eval_key}\"")
    if [[ "$format" == "json" ]]; then
      local js_pattern='[{](this[.][^}]+)[}]'
      while [[ "$eval_cmd" =~ $js_pattern ]]; do
        local js_expr="${BASH_REMATCH[1]:-${match[1]}}"
        local js_result=$(printf '%s' "$json" | jq -r ".${js_expr#this.}")
        eval_cmd="${eval_cmd/\{$js_expr\}/$js_result}"
      done
      if [[ "$has_output" == true ]]; then
        local return_value=$(printf '%s' "$json" | nvim -l "$__FZF_PICKER_LUA" --apply "$picker_name" output)
        eval_cmd="${eval_cmd//\{\}/$return_value}"
      fi
    else
      eval_cmd="${eval_cmd//\{\}/$json}"
    fi

    printf '//eval\n%s\n' "$eval_cmd"
    return
  fi

  result="$raw_output"
  [[ -z "$result" ]] && return
  if [[ "$has_output" == true && "$format" == "json" ]]; then
    if [[ "$shell_quote" == "true" ]]; then
      printf '%s\n' "$result" | cut -f1 | nvim -l "$__FZF_PICKER_LUA" --apply "$picker_name" output --print0 | while IFS= read -r -d '' val; do [[ -n "$val" ]] && printf '%q\n' "$val"; done
    else
      printf '%s\n' "$result" | cut -f1 | nvim -l "$__FZF_PICKER_LUA" --apply "$picker_name" output
    fi
  elif [[ "$has_output" == true ]]; then
    printf '%s\n' "$result" | eval "$output_shell"
  elif [[ "$has_fields" == true ]]; then
    printf '%s\n' "$result" | cut -f1
  elif [[ "$shell_quote" == "true" ]]; then
    printf '%s\n' "$result" | while IFS= read -r line; do [[ -n "$line" ]] && printf '%q\n' "$line"; done
  else
    printf '%s\n' "$result"
  fi
}

__fzf_lua_generate_functions
