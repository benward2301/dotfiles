#!/bin/sh

set -e

title="$1"
session_id="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "$title" ]; then
  if [ -t 0 ]; then
    echo "usage: title-session.sh <title>" >&2
    exit 1
  fi

  input=$(cat)
  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
    if [ -n "$session_id" ]; then
      transcript=$(fd -t f "^${session_id}\.jsonl$" "$HOME/.claude/projects" 2>/dev/null | head -1)
    fi
  fi
  if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
    exit 0
  fi
  title=$(grep '"type":"ai-title"' "$transcript" | tail -1 | jq -r '.aiTitle // empty')
  if [ -z "$title" ]; then
    exit 0
  fi
fi

if [ -z "$session_id" ]; then
  echo "title-session.sh: CLAUDE_CODE_SESSION_ID is not set" >&2
  exit 1
fi

export_dir="$HOME/.claude/session-exports"
export_file="$export_dir/${session_id}.md"
mkdir -p "$export_dir"
if [ -f "$export_file" ]; then
  tmp=$(mktemp)
  awk -v title="$title" '
    NR == 1 && $0 == "---" { print; infm = 1; next }
    infm && $0 == "---" { if (!placed) print "title: " title; infm = 0; print; next }
    infm && /^title:/ { next }
    infm && /^sessionId:/ { print; print "title: " title; placed = 1; next }
    { print }
  ' "$export_file" > "$tmp"
  mv "$tmp" "$export_file"
else
  printf '%s\n' "---" "sessionId: $session_id" "title: $title" "---" > "$export_file"
fi
if [ -n "${ATCH_SESSION:-}" ]; then
  atch-title "$title" || true
  printf '%s' "$title" > "/tmp/.atch_title_$(printf '%s' "${ATCH_SESSION##*:}" | tr '/:' '__')"
fi

printf '%s\n' "$title"
