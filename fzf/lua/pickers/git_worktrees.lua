local sh = require("utils.sh")

return {
  format = "json",

  width = "none",
  input = function()
    local parsed, maxlen = {}, 0
    for _, l in ipairs(sh.lines("git worktree list")) do
      local path, hash, bdisp = l:match("^(%S+)%s+(%S+)%s+(.*)$")
      if path then
        if #path > maxlen then maxlen = #path end
        parsed[#parsed + 1] = { path = path, hash = hash, bdisp = bdisp }
      end
    end

    local rows = {}
    for _, w in ipairs(parsed) do
      rows[#rows + 1] = {
        paddedPath = w.path .. string.rep(" ", maxlen + 1 - #w.path),
        path = w.path, hash = w.hash, branchDisplay = w.bdisp,
      }
    end
    return rows
  end,
  fields = {
    { expr = function(r) return r.paddedPath end, color = "blue" },
    { expr = function(r) return r.hash end, color = "yellow" },
    { expr = function(r) return r.branchDisplay end },
  },
  output = function(r) return r.path end,
}
