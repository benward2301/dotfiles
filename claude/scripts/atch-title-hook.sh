#!/bin/sh

[ -n "${ATCH_SESSION:-}" ] || exit 0

input=$(cat)
tf="/tmp/.atch_title_$(printf '%s' "${ATCH_SESSION##*:}" | tr '/:' '__')"

if [ -f "$tf" ]; then
  title=$(cat "$tf")
else
  title=""

  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
  export_file="$HOME/.claude/session-exports/${session_id}.md"
  if [ -n "$session_id" ] && [ -f "$export_file" ]; then
    title=$(awk '
      NR == 1 && $0 == "---" { infm = 1; next }
      infm && $0 == "---" { exit }
      infm && /^title:/ { sub(/^title: */, ""); print; exit }
    ' "$export_file")
  fi

  if [ -z "$title" ]; then
    title=$(printf '%s' "$input" | jq -r '.prompt // empty' | head -1 | cut -c1-100)
  fi
fi

[ -n "$title" ] || exit 0
atch-title "$title"
printf '%s' "$title" > "$tf"
