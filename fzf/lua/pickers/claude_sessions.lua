local expr = require("utils.expr")
local json = require("utils.json")
local sh = require("utils.sh")

local function parse_file(path)
  local fh = io.open(path)
  if not fh then return nil end
  local fm = 0
  local r = { sessionId = "", timestamp = "", cwd = "", gitBranch = "", title = "", summary = "", firstPrompt = "" }
  for line in fh:lines() do
    if line == "---" then
      fm = fm + 1
    elseif fm == 1 then
      local n = line:find(": ", 1, true)
      if n then
        local key, val = line:sub(1, n - 1), line:sub(n + 2)
        if key == "sessionId" then r.sessionId = val
        elseif key == "timestamp" then r.timestamp = val:gsub('"', "")
        elseif key == "cwd" then r.cwd = val
        elseif key == "gitBranch" then r.gitBranch = val
        elseif key == "title" then r.title = val
        elseif key == "summary" then r.summary = val end
      end
    elseif fm >= 2 and r.firstPrompt == "" then
      if line ~= "" and not line:match("^%*%*") and not line:match("<[a-z-]+>") and not line:match("^Tool ") then
        r.firstPrompt = line
      end
    end
  end
  fh:close()

  for _, k in ipairs({ "sessionId", "timestamp", "cwd", "gitBranch", "title", "summary", "firstPrompt" }) do
    r[k] = r[k]:gsub("%c", "")
  end
  return r
end

return {
  format = "json",
  no_space_accept = true,
  input = function()
    local home = os.getenv("HOME")
    local EXPORT_DIR = home .. "/.claude/session-exports"
    local PROJECTS_DIR = home .. "/.claude/projects"

    if not sh.ok("[ -d " .. sh.shquote(EXPORT_DIR) .. " ]") then return {} end
    local md_files = sh.lines("ls -1t " .. sh.shquote(EXPORT_DIR) .. "/*.md 2>/dev/null")
    if #md_files == 0 then return {} end

    local limit = os.getenv("FZF_CLAUDE_SESSIONS_ALL") == nil and 50 or nil

    local index = {}
    for _, idxfile in ipairs(sh.lines("fd -d 2 sessions-index.json " .. sh.shquote(PROJECTS_DIR) .. " 2>/dev/null")) do
      local fh = io.open(idxfile)
      if fh then
        local ok, doc = pcall(json.decode, fh:read("a") or "")
        fh:close()
        if ok and type(doc) == "table" and doc.entries then
          for _, e in ipairs(doc.entries) do
            if e.sessionId then
              index[e.sessionId] = (e.summary and e.summary ~= "") and e.summary or (e.firstPrompt or "")
            end
          end
        end
      end
    end

    local rows = {}
    for _, path in ipairs(md_files) do
      local r = parse_file(path)

      if r and r.sessionId ~= "" and r.cwd ~= "" and r.gitBranch ~= "" then
        local q = sh.shquote(r.cwd)
        local cwdExists = sh.ok("[ -d " .. q .. " ]")
        local branchExists, isMainBranch = false, false
        if cwdExists then
          if r.gitBranch ~= "" and sh.ok("git -C " .. q .. " show-ref --verify --quiet "
              .. sh.shquote("refs/heads/" .. r.gitBranch) .. " 2>/dev/null") then
            branchExists = true
          end
          local mb = sh.trim(sh.run("git -C " .. q .. " symbolic-ref refs/remotes/origin/HEAD 2>/dev/null"))
          mb = mb:gsub("refs/remotes/origin/", "")
          if mb == "" then mb = "main" end
          isMainBranch = (r.gitBranch == mb)
        end

        local summary
        if r.summary ~= "" then summary = r.summary
        elseif (index[r.sessionId] or "") ~= "" then summary = index[r.sessionId]
        else summary = r.firstPrompt end

        local cwd = r.cwd
        if cwd:sub(1, #home) == home then cwd = "~" .. cwd:sub(#home + 1) end

        rows[#rows + 1] = {
          sessionId = r.sessionId, timestamp = r.timestamp, cwd = cwd,
          gitBranch = r.gitBranch, title = r.title, summary = summary,
          firstPrompt = r.firstPrompt, exportPath = EXPORT_DIR .. "/" .. r.sessionId .. ".md",
          cwdExists = cwdExists, branchExists = branchExists, isMainBranch = isMainBranch,
        }
        if limit and #rows >= limit then break end
      end
    end
    return rows
  end,
  fields = {
    {
      expr = function(r)
        local s = expr.slice(r.timestamp, 0, 16)
        return s and (s:gsub("T", " ")) or nil
      end,
      width = { "fixed", 16 },
      color = "blue",
    },
    {
      expr = function(r) return r.cwd end,
      width = { "auto", { max = 50 } },
      colors = {
        { color = "green", expr = function(r) return r.cwdExists end },
        { color = "red" },
      },
    },
    {
      expr = function(r)
        if r.title and r.title ~= "" then return r.title end
        if r.summary and r.summary ~= "" then return r.summary end
        return r.sessionId
      end,
      color = "white",
    },
  },
  output = function(r) return r.exportPath end,
  preview = function(r)

    local ef = sh.shquote(os.getenv("HOME") .. "/.claude/session-exports/" .. r.sessionId .. ".md")
    local sid = sh.shquote(r.sessionId)
    return (sh.run(table.concat({
      "if [ -f ", ef, " ]; then ",
      [[awk '/^---$/ && fm<2{fm++; next} fm>=2{print}' ]], ef,
      [[ | CLICOLOR_FORCE=3 glow -s "${GLAMOUR_STYLE:-dark}" -; ]],
      "else markdown=$(~/.claude/scripts/extract-conversation.sh ", sid,
      [[ -n 500 2>/dev/null) || { echo "Session not found"; exit 0; }; ]],
      [[printf '%s\n' "$markdown" | CLICOLOR_FORCE=3 glow -s "${GLAMOUR_STYLE:-dark}" -; fi]],
    })))
  end,
  eval = {
    ["ctrl-r"] = [[cd {this.cwd} 2>/dev/null; TERM_PROGRAM= atch new -z "$(randname)" -- claude --permission-mode auto --resume {this.sessionId}]],
  },
  options = {
    height = "-5",
    ["preview-window"] = "right:40%,nohidden,<80(bottom,50%)",
    bind = {
      [[ctrl-o:become(${EDITOR:-nvim} $(cat {+f} | awk -F'\t' '{print $1}' | jq -r '.exportPath') > /dev/tty)]],
      [[ctrl-x:execute(${EDITOR:-nvim} $(cat {+f} | awk -F'\t' '{print $1}' | jq -r '.exportPath') > /dev/tty)]],
      [[alt-i:reload(FZF_CLAUDE_SESSIONS_ALL=1 {reload})]],
    },
  },
}
