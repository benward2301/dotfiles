#!/bin/sh

format="blockquote"
lines=""
session_id=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f) format="$2"; shift 2 ;;
    -n) lines="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) session_id="$1"; shift ;;
  esac
done

[ -z "$session_id" ] && session_id="$CLAUDE_SESSION_ID"
[ -z "$session_id" ] && echo "No session ID provided" >&2 && exit 1

session_file=$(fd -IH -e jsonl -t f . ~/.claude/projects 2>/dev/null | \
  grep -v '/agent-' | \
  xargs grep -l "\"sessionId\":\"$session_id\"" 2>/dev/null | \
  head -1)

[ -z "$session_file" ] && echo "Session not found: $session_id" >&2 && exit 1

read_cmd="cat"
[ -n "$lines" ] && read_cmd="tail -$lines"

if [ "$format" = "headers" ]; then
  $read_cmd "$session_file" | jq -rs '
    [.[] | select(.type == "user" or .type == "assistant") |
      if .type == "user" then
        { role: "USER", text: (.message.content | if type == "string" then . else "" end) }
      else
        { role: "ASSISTANT", text: (.message.content | if type == "array" then
            map(select(.type == "text") | .text) | join("") else "" end) }
      end | select(.text | length > 0)
    ] | .[] |
    "## " + .role + "\n\n" + .text + "\n\n---\n"
  '
else
  $read_cmd "$session_file" | jq -rs '
    [.[] | select(.type == "user" or .type == "assistant") |
      if .type == "user" then
        { role: "USER", text: (.message.content | if type == "string" then . else "" end) }
      else
        { role: "ASSISTANT", text: (.message.content | if type == "array" then
            map(select(.type == "text") | .text) | join("") else "" end) }
      end | select(.text | length > 0)
    ] | .[] |
    (if .role == "USER" then "> " + (.text | gsub("\n"; "\n> ")) else .text end) + "\n\n"
  '
fi
