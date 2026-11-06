
local function is_secret(name)
  local n = (name or ""):upper()
  return n:match("_KEY") or n:match("KEY$")
    or n:match("SECRET") or n:match("TOKEN")
    or n:match("PASSWORD") or n:match("PASSWD")
    or n:match("CREDENTIAL") or n:match("PRIVATE") ~= nil
end

return {
  command = [[jq -nc '$ENV | to_entries | sort_by(.key)[] | {name: .key, value: .value}']],
  format = "json",
  fields = {

    { expr = function(r) return r.name end },

    {
      expr = function(r)
        local v = r.value or ""
        if v ~= "" and is_secret(r.name) then return "********" end
        return v
      end,
      color = "green",
    },
  },
  output = function(r) return r.name end,
  options = { multi = true },
}
