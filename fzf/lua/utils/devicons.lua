
local colors = require('utils.colors')
local data = require('data.devicons')

local M = {}

local variant = data[colors.is_dark() and 'dark' or 'light']

local by_filename, by_ext, by_ext_2part, ext_has_2part = {}, {}, {}, {}
for k, v in pairs(variant.by_filename) do
  by_filename[k:lower()] = v
end
for k, v in pairs(variant.by_extension) do
  local key = k:lower()
  if key:find('.', 1, true) then
    by_ext_2part[key] = v
    ext_has_2part[key:match('([^.]+)$')] = true
  else
    by_ext[key] = v
  end
end

local function tail(path)
  return path:match('([^/]*)$')
end

local function last_ext(name)
  return name:match('%.([^.]+)$')
end

local function lookup(path)
  local name = tail(path):lower()
  local hit = by_filename[name]
  if hit then return hit end

  local ext = last_ext(name)
  if ext then
    if ext_has_2part[ext] then
      local stem = name:sub(1, #name - #ext - 1)
      local ext2 = last_ext(stem)
      if ext2 then
        local two = by_ext_2part[ext2 .. '.' .. ext]
        if two then return two end
      end
    end
    local one = by_ext[ext]
    if one then return one end
  end

  return data.default
end

function M.icon(path)
  local r = lookup(path)
  return r.icon, r.color
end

function M.dir_icon()
  return data.dir.icon, data.dir.color
end

function M.ansi(path)
  local glyph, color = M.icon(path)
  if color and color ~= '' then
    return colors.resolve(color) .. glyph .. colors.RESET
  end
  return glyph
end

function M.ansi_dir()
  local glyph, color = M.dir_icon()
  if color and color ~= '' then
    return colors.resolve(color) .. glyph .. colors.RESET
  end
  return glyph
end

return M
