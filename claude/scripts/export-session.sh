#!/bin/sh

set -e

EXPORT_DIR="$HOME/.claude/session-exports"
PROJECTS_DIR="$HOME/.claude/projects"

JQ_EXTRACT='
  [.[] | select(.sessionId != null)] |
  ([.[] | select(.type == "assistant")] | max_by(.timestamp) // null) as $last |
  (if $last != null then $last else .[0] end) as $meta |
  {
    sessionId: $meta.sessionId,
    cwd: $meta.cwd,
    gitBranch: (($meta.gitBranch | if . == "" or . == null then "-" else . end)),
    timestamp: $meta.timestamp,
    body: (
    [.[] | select((.type == "user" or .type == "assistant") and (.isMeta != true)) |
      { role: .type, text: (.message.content | if type == "array" then
          ([.[] | select(.type == "text") | .text
            | select(startswith("Base directory for this skill:") | not)]) | join("")
          elif type == "string" then . else "" end) }
      | select(.text | length > 0)
    ] as $msgs | $msgs | to_entries |
    map(
      (if .key == 0 or .value.role != $msgs[.key - 1].role
       then (if .key == 0 then "" else "\n\n---\n\n" end) + "**" + (if .value.role == "user" then "👤 USER" else "🤖 ASSISTANT" end) + "**\n\n" else "" end) +
      .value.text
    ) | join("\n\n"))
  }
'

export_single() {
  jsonl_path="$1"

  [ ! -s "$jsonl_path" ] && return 0 || true

  data=$(jq -s "$JQ_EXTRACT" "$jsonl_path" 2>/dev/null) || return 0

  session_id=$(printf '%s' "$data" | jq -r '.sessionId // empty')
  [ -z "$session_id" ] && return 0 || true

  mkdir -p "$EXPORT_DIR"

  title=""
  if [ -f "$EXPORT_DIR/${session_id}.md" ]; then
    title=$(awk '
      NR == 1 && $0 == "---" { infm = 1; next }
      infm && $0 == "---" { exit }
      infm && /^title:/ { sub(/^title: */, ""); print; exit }
    ' "$EXPORT_DIR/${session_id}.md")
  fi

  {
    printf '%s\n' "---"
    printf '%s\n' "$data" | jq -r '
      "sessionId: " + .sessionId,
      "timestamp: \"" + .timestamp + "\"",
      "cwd: " + .cwd,
      "gitBranch: " + .gitBranch'
    printf 'title: %s\n' "$title"
    printf '%s\n' "---"
    printf '\n'
    printf '%s\n' "$data" | jq -r '.body'
  } > "$EXPORT_DIR/${session_id}.md"

  timestamp=$(printf '%s' "$data" | jq -r '.timestamp')
  touch -d "$timestamp" "$EXPORT_DIR/${session_id}.md"
}

if [ "$1" = "--all" ]; then
  mkdir -p "$EXPORT_DIR"
  marker="$EXPORT_DIR/.last-export"

  fd -d 2 -g '*-*-*-*-*.jsonl' "$PROJECTS_DIR" 2>/dev/null | \
    grep -v '/agent-' | \
    while IFS= read -r jsonl; do
      [ ! -s "$jsonl" ] && continue
      basename_noext=$(basename "$jsonl" .jsonl)
      export_file="$EXPORT_DIR/${basename_noext}.md"
      [ -f "$export_file" ] && [ -f "$marker" ] && [ "$marker" -nt "$jsonl" ] && continue || true
      printf '%s\n' "$jsonl"
    done | \
    xargs -P 8 -I{} "$0" "{}"
  touch "$marker"
  exit 0
fi

input="$1"

if [ -f "$input" ] && printf '%s' "$input" | grep -q '\.jsonl$'; then
  jsonl_path="$input"
else
  jsonl_path=$(fd -IH -e jsonl -t f . "$PROJECTS_DIR" 2>/dev/null | \
    grep -v '/agent-' | \
    xargs grep -l "\"sessionId\":\"$input\"" 2>/dev/null | \
    head -1)
  if [ -z "$jsonl_path" ]; then echo "Session not found: $input" >&2; exit 1; fi
fi

export_single "$jsonl_path"
