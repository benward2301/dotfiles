
local colors = {}

colors.RESET = '\27[0m'

local function load_scheme()
  local path = (os.getenv('HOME') or '') .. '/.local/share/foxglove/colorscheme.lua'
  local ok, scheme = pcall(dofile, path)
  if not ok or type(scheme) ~= 'table' then return nil end
  return scheme
end
function colors.is_dark()
  local scheme = load_scheme()
  return scheme == nil or scheme.dark ~= false
end

local function build_map()
  local scheme = load_scheme()
  if not scheme then return {} end

  local m = {}
  for k, v in pairs(scheme) do
    if type(v) == 'string' and v:match('^#%x+$') then m[k] = v end
  end
  local aliases = {}
  for k, v in pairs(m) do
    local family = k:match('^(%a+)1$')
    if family and family ~= 'ansi' then aliases[family] = v end
  end
  for family, v in pairs(aliases) do m[family] = v end
  if m.text then m.white = m.text end
  return m
end

local map = nil

local function hex_to_ansi(hex)
  hex = hex:gsub('#', '')
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  return ('\27[38;2;%d;%d;%dm'):format(r, g, b)
end
function colors.resolve(name)
  if not name or name == '' then return '' end
  if map == nil then map = build_map() end
  return hex_to_ansi(map[name] or name)
end
function colors.dim_dir(path, name)
  local trailing = path:sub(-1) == '/'
  local core = trailing and path:sub(1, -2) or path
  local dir = core:match('^(.*/)')
  if not dir then return path end
  local leaf = core:sub(#dir + 1) .. (trailing and '/' or '')
  return colors.resolve(name) .. dir .. colors.RESET .. leaf
end
function colors.split_dir(path, parent_name, leaf_name)
  local trailing = path:sub(-1) == '/'
  local core = trailing and path:sub(1, -2) or path
  local dir = core:match('^(.*/)') or ''
  local leaf = core:sub(#dir + 1) .. (trailing and '/' or '')
  local out = colors.resolve(leaf_name) .. leaf .. colors.RESET
  if dir ~= '' then
    out = colors.resolve(parent_name) .. dir .. colors.RESET .. out
  end
  return out
end

return colors
