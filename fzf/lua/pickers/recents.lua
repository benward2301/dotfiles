local json = require("utils.json")

return {
  format = "json",
  input = function()
    local home = os.getenv("HOME") or ""
    local file = home .. "/.local/state/fzf-picker-recents"
    local fh = io.open(file)
    if not fh then return {} end

    local best, order = {}, {}
    for line in fh:lines() do
      if line:match("%S") then
        local ok, r = pcall(json.decode, line)
        if ok and type(r) == "table" and r.value ~= nil then
          local cur = best[r.value]
          if not cur then
            order[#order + 1] = r.value
            best[r.value] = r
          elseif (r.ts or 0) > (cur.ts or 0) then
            best[r.value] = r
          end
        end
      end
    end
    fh:close()
    table.sort(order, function(a, b) return (best[a].ts or 0) > (best[b].ts or 0) end)

    local rows = {}
    for _, v in ipairs(order) do
      local item = best[v]
      rows[#rows + 1] = { value = item.value, picker = item.picker }
    end
    return rows
  end,
  fields = {
    { expr = function(r) return r.picker end, color = "blue" },
    { expr = function(r) return r.value end },
  },
  output = function(r) return r.value end,
  copy = function(r) return r.value end,
  options = {
    ["no-sort"] = true,
  },
}
