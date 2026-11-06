
__FZF_COMBINED_MRU_FILE="${__FZF_COMBINED_MRU_FILE:-/tmp/fzf-combined-mru-$(id -u)}"

__fzf_combined_mru_get() {
  local name="$1"
  [[ -f "$__FZF_COMBINED_MRU_FILE" ]] || return 1
  while read -r n ts; do
    [[ "$n" == "$name" ]] && { echo "$ts"; return; }
  done < "$__FZF_COMBINED_MRU_FILE"
}

__fzf_combined_mru_set() {
  local name="$1"
  local ts=$(date +%s)
  local tmp="${__FZF_COMBINED_MRU_FILE}.tmp"
  {
    echo "$name $ts"
    if [[ -f "$__FZF_COMBINED_MRU_FILE" ]]; then
      while read -r n t; do
        [[ "$n" != "$name" ]] && echo "$n $t" || true
      done < "$__FZF_COMBINED_MRU_FILE"
    fi
  } > "$tmp" && mv "$tmp" "$__FZF_COMBINED_MRU_FILE"
}
