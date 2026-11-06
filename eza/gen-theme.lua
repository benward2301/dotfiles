
local out_dir = arg[1] or "."

local function find_data_file(subdir, name)
  local rel = subdir .. "/" .. name
  local candidates = {
    vim.fn.stdpath("data") .. "/lazy/nvim-web-devicons/lua/nvim-web-devicons/" .. rel,
  }
  for _, p in ipairs(vim.fn.glob(
    vim.fn.stdpath("data") .. "/site/pack/*/*/nvim-web-devicons/lua/nvim-web-devicons/" .. rel,
    false, true
  )) do
    candidates[#candidates + 1] = p
  end
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then
      return p
    end
  end
  error("could not locate nvim-web-devicons data file: " .. rel)
end

local function load_table(subdir, name)
  return dofile(find_data_file(subdir, name))
end

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

local function title_case(name)
  return (name:gsub("%a", string.upper, 1))
end

local function entry(key, color)
  return string.format('  "%s": { icon: { style: { foreground: "%s" } } }', key, color)
end

local function ascii_key(key)
  return not key:find("[\128-\255]")
end
local function low_contrast(color, drop_white, drop_black)
  local r, g, b = color:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    return false
  end
  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  local lo, hi = math.min(r, g, b), math.max(r, g, b)
  local chroma = hi - lo
  if drop_white and lo >= 185 and chroma <= 30 then
    return true
  end
  if drop_black and hi <= 70 and chroma <= 30 then
    return true
  end
  return false
end
local VARIANTS = {
  { name = "dark", subdir = "default", drop_white = false, drop_black = true },
  { name = "light", subdir = "light", drop_white = true, drop_black = false },
  { name = "universal", subdir = "default", drop_white = true, drop_black = true },
}

local function generate(v)
  local by_extension = load_table(v.subdir, "icons_by_file_extension.lua")
  local by_filename = load_table(v.subdir, "icons_by_filename.lua")

  local function usable(color)
    return color and not low_contrast(color, v.drop_white, v.drop_black)
  end

  local lines = { "extensions:" }
  local seen_ext = {}
  for _, ext in ipairs(sorted_keys(by_extension)) do
    local color = by_extension[ext].color
    local folded = ext:lower()
    if usable(color) and ascii_key(folded) and not folded:find("%.") and not seen_ext[folded] then
      seen_ext[folded] = true
      lines[#lines + 1] = entry(folded, color)
    end
  end

  lines[#lines + 1] = "filenames:"
  local seen_name = {}
  local function emit_name(key, color)
    if usable(color) and ascii_key(key) and not seen_name[key] then
      seen_name[key] = true
      lines[#lines + 1] = entry(key, color)
    end
  end
  for _, name in ipairs(sorted_keys(by_filename)) do
    local color = by_filename[name].color
    emit_name(name, color)
    if name:match("^%a") then
      emit_name(title_case(name), color)
    end
  end

  local path = out_dir .. "/theme-" .. v.name .. ".yml"
  local f = assert(io.open(path, "w"))
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()

  local count = 0
  for _, line in ipairs(lines) do
    if line:find("foreground") then
      count = count + 1
    end
  end
  print(string.format("wrote %s (%d icon colors)", path, count))
end

for _, v in ipairs(VARIANTS) do
  generate(v)
end
