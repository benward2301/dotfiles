local sh = require("utils.sh")

return {
  format = "json",
  input = function()
    local home = os.getenv("HOME")
    local roles_dir = home .. "/.config/aichat/roles"
    local config_file = home .. "/.config/aichat/config.yaml"
    local default_model = sh.trim(sh.run([[yq -r '.model // ""' ]] .. sh.shquote(config_file) .. " 2>/dev/null"))

    local recs = {}
    for _, role in ipairs(sh.lines("aichat --list-roles")) do
      local role_file = roles_dir .. "/" .. role .. ".md"
      local model, is_default
      if sh.ok("[ -f " .. sh.shquote(role_file) .. " ]") then
        model = sh.trim(sh.run([[yq -r --front-matter=extract '.model // ""' ]] .. sh.shquote(role_file) .. " 2>/dev/null"))
        if model == "" then model = default_model; is_default = true else is_default = false end
      else
        model = default_model
        is_default = true
      end
      recs[#recs + 1] = {
        role = role, model = model, isDefault = is_default,
        isStock = role:match("^%%.*%%$") ~= nil,
      }
    end
    table.sort(recs, function(a, b)
      local av = a.isStock and 1 or 0
      local bv = b.isStock and 1 or 0
      if av ~= bv then return av < bv end
      return a.role < b.role
    end)
    return recs
  end,
  fields = {
    { expr = function(r) return r.role end },
  },
  output = function(r) return r.role end,
  preview = function(r)
    local role_file = os.getenv("HOME") .. "/.config/aichat/roles/" .. r.role .. ".md"
    return (sh.run("role_file=" .. sh.shquote(role_file)
      .. [[; [ -f "$role_file" ] && awk 'NR == 1 && /^---$/ { print "```yaml"; in_frontmatter = 1; next } in_frontmatter && /^---$/ { print "```"; in_frontmatter = 0; next } { print }' "$role_file" | CLICOLOR_FORCE=3 glow -s "${GLAMOUR_STYLE:-dark}" - || echo 'Stock role (no file)']]))
  end,
  options = {
    bind = {
      [[ctrl-o:become(role_file="$HOME/.config/aichat/roles/$(printf '%s' {1} | jq -r '.role').md"; [ -f "$role_file" ] && ${EDITOR:-nvim} "$role_file" > /dev/tty)]],
      [[ctrl-x:execute(role_file="$HOME/.config/aichat/roles/$(printf '%s' {1} | jq -r '.role').md"; [ -f "$role_file" ] && ${EDITOR:-nvim} "$role_file" > /dev/tty)]],
    },
  },
}
