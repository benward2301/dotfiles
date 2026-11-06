local sh = require("utils.sh")

return {
  format = "json",
  input = function()
    local dir = os.getenv("HOME") .. "/.config/aichat/sessions"
    local listing = "eza -l -s modified --reverse --time-style='+%Y-%m-%d %H:%M'"
      .. " --no-permissions --no-user --no-filesize --icons=never --color=never "
      .. sh.shquote(dir) .. " 2>/dev/null"

    local limit = os.getenv("FZF_AICHAT_SESSIONS_ALL") == nil and 50 or nil

    local rows = {}
    for _, line in ipairs(sh.lines(listing)) do
      local date, time, fname = line:match("^(%S+)%s+(%S+)%s+(.+)$")
      if fname then
        local q = sh.shquote(dir .. "/" .. fname)
        local role = sh.trim(sh.run([[yq -r '.role_name // ""' ]] .. q .. " 2>/dev/null"))
        local prompt = sh.run([[yq -r '[.messages[] | select(.role == "user")] | .[0].content // "" | split("\n") | .[0]' ]]
          .. q .. " 2>/dev/null")
        prompt = (prompt:match("[^\n]*") or ""):sub(1, 80)
        rows[#rows + 1] = { path = dir .. "/" .. fname, datetime = date .. " " .. time, role = role, prompt = prompt }
        if limit and #rows >= limit then break end
      end
    end
    return rows
  end,
  fields = {
    { expr = function(r) return r.datetime end, color = "blue" },
    { expr = function(r) return r.role end, width = "auto", color = "green" },
    { expr = function(r) return r.prompt end },
  },
  output = function(r) return r.path end,
  preview = function(r)
    local f = sh.shquote(r.path)
    local jq = [==[[.[] | select(.role == "user" or .role == "assistant") | { role: .role, text: .content }] as $msgs | $msgs | to_entries | map((if .key == 0 or .value.role != $msgs[.key - 1].role then (if .key == 0 then "" else "\n\n---\n\n" end) + "**" + (if .value.role == "user" then "👤 USER" else "🤖 ASSISTANT" end) + "**\n\n" else "" end) + .value.text) | join("\n\n")]==]
    local cmd = "[ -f " .. f .. [[ ] || exit 0; { printf '```yaml\n'; yq 'del(.messages)' ]] .. f
      .. [[; printf '```\n'; echo; yq -o=json '.messages' ]] .. f .. " | jq -r " .. sh.shquote(jq)
      .. [[; } | CLICOLOR_FORCE=3 glow -s "${GLAMOUR_STYLE:-dark}" -]]
    return (sh.run(cmd))
  end,
  options = {
    ["no-multi"] = true,
    ["preview-window"] = "right:40%",
    bind = {
      [[ctrl-o:become:${EDITOR:-nvim} $(printf '%s' {1} | jq -r '.path') < /dev/tty > /dev/tty]],
      [[ctrl-r:become:session=$(basename $(printf '%s' {1} | jq -r '.path') .yaml); aichat --save-session -s $session < /dev/tty > /dev/tty]],
      [[ctrl-x:execute:nvim $(printf '%s' {1} | jq -r '.path') > /dev/tty]],
      [[alt-i:reload(FZF_AICHAT_SESSIONS_ALL=1 {reload})]],
    },
  },
}
