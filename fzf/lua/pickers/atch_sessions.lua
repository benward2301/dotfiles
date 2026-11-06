local sh = require("utils.sh")
local function parse_line(line)
  local name, rest = line:match("^(%S+)%s+(.+)$")
  if not name then return nil end
  local age = rest:match("^since (.-) ago")
  if not age then return nil end
  local tag = rest:match("%[(%a+)%]%s*$")
  if tag == "stale" then return nil end
  local status = tag == "attached" and "Attached" or "Detached"
  return { name = name, age = age, status = status }
end

return {
  format = "json",
  input = function()
    local recs = {}
    for _, line in ipairs(sh.lines("atch list 2>/dev/null")) do
      local r = parse_line(line)
      if r then
        local title_file = os.getenv("HOME") .. "/.cache/atch/" .. r.name .. ".title"
        r.title = sh.trim(sh.run("cat " .. sh.shquote(title_file) .. " 2>/dev/null"))
        recs[#recs + 1] = r
      end
    end
    local order = {}
    for i = 1, #recs do order[i] = i end
    table.sort(order, function(x, y)
      local a = recs[x].status == "Attached" and 1 or 0
      local b = recs[y].status == "Attached" and 1 or 0
      if a ~= b then return a < b end
      return x < y
    end)
    local rows = {}
    for _, i in ipairs(order) do rows[#rows + 1] = recs[i] end
    return rows
  end,
  fields = {
    { expr = function(r) return r.age end, color = "blue" },
    {
      expr = function(r) return r.status end,
      colors = {
        { color = "green", values = { "Attached" } },
        { color = "yellow" },
      },
    },
    { expr = function(r) return r.name end, color = "cyan" },
    { expr = function(r) return r.title end, color = "white" },
  },
  output = function(r) return r.name end,
  eval = {
    ["ctrl-o"] = [[atch {}]],
    ["ctrl-r"] = [[atch {}]],
  },
}
