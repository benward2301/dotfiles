
local M = {}

local cache_dir = os.getenv('HOME') .. '/.local/share/foxglove'

local function write_cache(name, p)
  local path = cache_dir .. '/colorscheme.lua'

  local color_keys = {}
  for k, v in pairs(p) do
    -- consumers derive the ansi slots from the named colours
    if type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') and not k:match('^ansi') then
      color_keys[#color_keys + 1] = k
    end
  end
  table.sort(color_keys)

  local f = assert(io.open(path, 'w'))
  f:write('return {\n')
  f:write(string.format("  name = '%s',\n", p.name or name))
  f:write(string.format('  dark = %s,\n', tostring(p.dark and true or false)))
  for _, k in ipairs(color_keys) do
    f:write(string.format("  %s = '%s',\n", k, p[k]))
  end
  f:write('}\n')
  f:close()
  return path
end

local function need(p, keys)
  local out = {}
  for _, key in ipairs(keys) do
    assert(type(p[key]) == 'string', 'artifacts: palette has no ' .. key)
    out[key] = p[key]
  end
  return out
end

local function write_delta(p)
  local c = need(p, { 'green4', 'green3', 'red4', 'red3', 'subtext1' })
  local dir = os.getenv('HOME') .. '/.config/delta'
  vim.fn.mkdir(dir, 'p')
  local f = assert(io.open(dir .. '/theme', 'w'))
  f:write(string.format([[
[delta]
  %s = true
  syntax-theme = foxglove
  plus-style = syntax "%s"
  plus-emph-style = syntax "%s"
  minus-style = syntax "%s"
  minus-emph-style = syntax "%s"
  line-numbers-zero-style = "%s" dim
]], p.dark and 'dark' or 'light', c.green4, c.green3, c.red4, c.red3, c.subtext1))
  f:close()
end

local function write_lnav(p)
  local dir = cache_dir .. '/lnav'
  vim.fn.mkdir(dir, 'p')
  local vars = { semantic_highlight_color = 'semantic()' }
  for k, v in pairs(p) do
    if type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') then
      vars[k] = v
    end
  end
  local doc = {
    ['$schema'] = 'https://lnav.org/schemas/config-v1.schema.json',
    ui = { ['theme-defs'] = { foxglove = { vars = vars } } },
  }
  local f = assert(io.open(dir .. '/foxglove-palette.json', 'w'))
  f:write(vim.json.encode(doc))
  f:close()
end

function M.write(name, palette)
  local p = palette or require('foxglove').palette or {}
  assert(p.base1, 'artifacts: no palette applied')
  vim.fn.mkdir(cache_dir, 'p')

  local cache = write_cache(name, p)
  write_delta(p)
  write_lnav(p)
  return cache
end

return M
