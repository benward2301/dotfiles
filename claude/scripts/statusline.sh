#!/bin/sh

cyan='\033[36m'
magenta='\033[35m'
green='\033[32m'
red='\033[31m'
reset='\033[0m'

input=$(cat)
current_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')

humanize() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) { v = n / 1000000; suffix = "m" }
    else if (n >= 1000) { v = n / 1000; suffix = "k" }
    else { printf "%d", n; exit }
    if (v == int(v)) printf "%d%s", v, suffix
    else printf "%.1f%s", v, suffix
  }'
}

in_git_repo() {
  git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1
}

git_field() {
  git -C "$current_dir" --no-optional-locks "$@" 2>/dev/null
}

if in_git_repo; then
  repo_root=$(git_field rev-parse --show-toplevel)
  repo_name=$(basename "$repo_root")
  rel_path=${current_dir#"$repo_root"}
  rel_path=${rel_path#/}
  if [ -n "$rel_path" ]; then
    display_dir="$repo_name/$rel_path"
  else
    display_dir="$repo_name"
  fi
else
  case "$current_dir" in
    "$HOME"*) display_dir="~${current_dir#"$HOME"}" ;;
    *) display_dir="$current_dir" ;;
  esac
fi

output=$(printf "${cyan}%s${reset}" "$display_dir")

if in_git_repo; then
  branch=$(git_field branch --show-current)
  if [ -n "$branch" ]; then
    output="$output on $(printf "${magenta}%s${reset}" " $branch")"
  fi
fi

used=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
limit=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')
pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // (100 * (.context_window.total_input_tokens // 0) / (.context_window.context_window_size // 200000))')
if awk -v p="$pct" 'BEGIN { exit !(p < 75) }'; then
  tokens_color="$green"
else
  tokens_color="$red"
fi
output="$output $(printf "${tokens_color}[%s/%s]${reset}" "$(humanize "$used")" "$(humanize "$limit")")"

printf '%s\n' "$output"
