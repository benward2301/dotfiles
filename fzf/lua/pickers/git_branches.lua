local sh = require("utils.sh")

local function list()
  local current = sh.trim(sh.run("git symbolic-ref --short HEAD 2>/dev/null"))

  local worktree = {}
  for _, l in ipairs(sh.lines("git worktree list --porcelain 2>/dev/null")) do
    local b = l:match("^branch refs/heads/(.+)$")
    if b then worktree[b] = true end
  end

  local tracked = {}
  for _, l in ipairs(sh.lines("git for-each-ref refs/heads/ --format='%(upstream:short)'")) do
    if l ~= "" then tracked[l] = true end
  end

  local FMT = "--format='%(refname:short)\t%(committerdate:relative)\t%(authorname)\t%(objectname:short)\t%(subject)'"
  local rows = {}
  local function gather(ref, typ)
    for _, l in ipairs(sh.lines("git for-each-ref --sort=-committerdate " .. ref .. " " .. FMT)) do
      local branch, date, author, hash, subject = l:match("^(.-)\t(.-)\t(.-)\t(.-)\t(.*)$")

      if branch and not (typ == "remote" and (branch:match("/HEAD$") or tracked[branch])) then
        rows[#rows + 1] = { type = typ, branch = branch, date = date, author = author, hash = hash, message = subject }
      end
    end
  end
  gather("refs/heads/", "local")
  gather("refs/remotes/", "remote")

  local out = {}
  for _, r in ipairs(rows) do
    local isCurrent = (r.type == "local" and r.branch == current)
    local isWorktree = (r.type == "local" and r.branch ~= current and worktree[r.branch] == true)
    local isRemote = (r.type == "remote")
    local marker = isCurrent and "*" or (isWorktree and "+" or " ")
    out[#out + 1] = {
      branch = r.branch, marker = marker,
      date = r.date, author = r.author, hash = r.hash, message = r.message,
      isCurrent = isCurrent, isWorktree = isWorktree, isRemote = isRemote,
    }
  end
  return out
end

return {
  format = "json",
  input = list,
  fields = {
    { expr = function(r) return r.marker end, width = { "fixed", 1 }, color = "white" },
    {
      expr = function(r) return r.branch end,
      width = { "auto", { max = 80 } },
      colors = {
        { color = "green", expr = function(r) return r.isCurrent end },
        { color = "cyan", expr = function(r) return r.isWorktree end },
        { color = "red", expr = function(r) return r.isRemote end },
        { color = "white" },
      },
    },
    { expr = function(r) return " " .. r.hash end, width = { "fixed", 9 }, color = "yellow" },
    { expr = function(r) return r.date end, width = { "fixed", 15 }, color = "blue" },
    { expr = function(r) return r.author end, width = { "fixed", 15 }, color = "green" },
    { expr = function(r) return r.message end, color = "white" },
  },
  output = function(r) return r.branch end,
}
