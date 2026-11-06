
local colors = require('utils.colors')
local devicons = require('utils.devicons')

local M = {}

local DEFAULT_DYNAMIC_MAX = 80

local GAP = '  '

local SGR = '\27%[[0-9;:]*m'

local function ulen(s)
  local visible = (s:gsub(SGR, ''))
  local _, n = visible:gsub('[^\128-\191]', '')
  return n
end

local function unext(s, i)
  local b = s:byte(i)
  if not b then return nil end
  local width = 1
  if b >= 0xF0 then width = 4
  elseif b >= 0xE0 then width = 3
  elseif b >= 0xC0 then width = 2
  end
  local nxt = i + width
  if nxt > #s + 1 then return nil end
  return nxt
end

local function fit(s, w)
  local n = ulen(s)
  if n == w then return s end
  if n < w then return s .. string.rep(' ', w - n) end

  local out, count, i = {}, 0, 1
  while i <= #s and count < w do
    local esc = s:match('^' .. SGR, i)
    if esc then
      out[#out + 1] = esc; i = i + #esc
    else
      local nxt = unext(s, i)
      if not nxt then out[#out + 1] = s:sub(i); break end
      out[#out + 1] = s:sub(i, nxt - 1); count = count + 1; i = nxt
    end
  end
  if s:find(SGR) then out[#out + 1] = '\27[0m' end
  return table.concat(out)
end

local function pad_min(s, minw)
  if not minw then return s end
  local n = ulen(s)
  if n < minw then return s .. string.rep(' ', minw - n) end
  return s
end

local function normalize_width(spec)
  if spec == nil then return { mode = 'auto' } end
  if type(spec) == 'string' then
    if spec == 'none' then return { mode = 'none' } end
    return { mode = 'auto' }
  end
  local mode = spec[1]
  if mode == 'fixed' then return { mode = 'fixed', n = spec[2] } end
  if mode == 'none' then return { mode = 'none' } end
  if mode == 'auto' then
    local mm = spec[2]
    return { mode = 'auto', min = mm and mm.min, max = mm and mm.max }
  end
  return { mode = 'auto' }
end

local function split(s, sep)
  local out, i = {}, 1
  while true do
    local j = s:find(sep, i, true)
    if not j then out[#out + 1] = s:sub(i); break end
    out[#out + 1] = s:sub(i, j - 1)
    i = j + 1
  end
  return out
end

local function collapse_path(path)
  local parts = split(path, '/')
  if #parts <= 1 then return path end
  local out = {}
  for k = 1, #parts - 1 do
    local seg = parts[k]
    out[k] = seg ~= '' and seg:sub(1, 1) or seg
  end
  out[#out + 1] = parts[#parts]
  return table.concat(out, '/')
end

local function compute_raw(field, record)
  local ok, value = pcall(field.expr, record)
  local raw
  if not ok then
    raw = '[error: ' .. tostring(value) .. ']'
  elseif value == nil then
    raw = ''
  else
    raw = tostring(value)
  end
  raw = raw:gsub('\n', '\\n')
  if field.collapsePathAt and ulen(raw) >= field.collapsePathAt then
    raw = collapse_path(raw)
  end
  return raw
end

local function eval_color(rules, record, raw)
  for _, rule in ipairs(rules) do
    local match
    if rule.expr then
      local ok, res = pcall(rule.expr, record)
      match = ok and res and true or false
    elseif rule.values then
      match = false
      for _, v in ipairs(rule.values) do
        if v == raw then match = true; break end
      end
    elseif rule.pattern then
      match = raw:find(rule.pattern) ~= nil
    elseif rule.gte ~= nil then
      local n = tonumber(raw); match = n ~= nil and n >= rule.gte
    elseif rule.gt ~= nil then
      local n = tonumber(raw); match = n ~= nil and n > rule.gt
    elseif rule.lte ~= nil then
      local n = tonumber(raw); match = n ~= nil and n <= rule.lte
    elseif rule.lt ~= nil then
      local n = tonumber(raw); match = n ~= nil and n < rule.lt
    else
      match = true
    end
    if match then return colors.resolve(rule.color) end
  end
  return ''
end

function M.format_all(picker, records)
  local fields = picker.fields or {}
  if #fields == 0 then return {} end

  local specs = {}
  local forced_none = false
  for idx, f in ipairs(fields) do
    local spec

    if f.icon then
      spec = { mode = 'icon' }
    elseif forced_none then
      spec = { mode = 'none' }
    else
      spec = normalize_width(f.width ~= nil and f.width or picker.width)
      if spec.mode == 'none' then forced_none = true end
    end
    specs[idx] = spec
  end

  local raws, observed = {}, {}
  for ri, rec in ipairs(records) do
    raws[ri] = {}
    for fi, f in ipairs(fields) do
      local raw = compute_raw(f, rec)
      raws[ri][fi] = raw
      if specs[fi].mode == 'auto' then
        local n = ulen(raw)
        if not observed[fi] or n > observed[fi] then observed[fi] = n end
      end
    end
  end

  local last = #fields
  for fi, spec in ipairs(specs) do
    if spec.mode == 'auto' then
      local w = observed[fi] or 0
      if spec.min then w = math.max(w, spec.min) end
      if spec.max then
        spec.width = math.min(w, spec.max)
      elseif fi == last then
        spec.width = nil
      else
        spec.width = math.min(w, DEFAULT_DYNAMIC_MAX)
      end
    elseif spec.mode == 'fixed' then
      spec.width = spec.n
    end
  end

  local out = {}
  for ri, rec in ipairs(records) do
    local parts = {}
    for fi, f in ipairs(fields) do
      local spec = specs[fi]
      local raw = raws[ri][fi]
      if spec.mode == 'icon' then

        parts[#parts + 1] = devicons.ansi(raw)
      elseif not (raw == '' and spec.mode == 'none') then
        local disp
        if spec.mode == 'none' then
          disp = raw
        elseif spec.width ~= nil then
          disp = fit(raw, spec.width)
        else
          disp = pad_min(raw, spec.min)
        end

        if f.dir_color then

          disp = colors.dim_dir(disp, f.dir_color)
        else
          local color = ''
          if f.colors then
            color = eval_color(f.colors, rec, raw)
          elseif f.color then
            color = colors.resolve(f.color)
          end
          if color ~= '' then disp = color .. disp .. colors.RESET end
        end

        if f.pad == false then disp = disp .. '\0' end
        parts[#parts + 1] = disp
      end
    end
    out[ri] = (table.concat(parts, GAP):gsub('%z' .. GAP, ''):gsub('%z$', ''))
  end
  return out
end

return M
