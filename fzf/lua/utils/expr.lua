
local expr = {}

function expr.get(t, ...)
  for _, k in ipairs({ ... }) do
    if type(t) ~= 'table' then return nil end
    t = t[k]
  end
  return t
end

function expr.find(arr, key_or_pred, value)
  if type(arr) ~= 'table' then return nil end
  if type(key_or_pred) == 'function' then
    for _, v in ipairs(arr) do
      if key_or_pred(v) then return v end
    end
  else
    for _, v in ipairs(arr) do
      if type(v) == 'table' and v[key_or_pred] == value then return v end
    end
  end
  return nil
end

function expr.slice(s, start, stop)
  if s == nil then return nil end
  s = tostring(s)
  local len = #s
  start = start or 0
  if start < 0 then start = math.max(len + start, 0) end
  if stop == nil then stop = len else
    if stop < 0 then stop = len + stop end
    stop = math.min(stop, len)
  end
  if stop <= start then return '' end
  return s:sub(start + 1, stop)
end

function expr.last_index(s, sub)
  if s == nil then return -1 end
  s = tostring(s)
  local last = -1
  local from = 1
  while true do
    local i = s:find(sub, from, true)
    if not i then break end
    last = i - 1
    from = i + 1
  end
  return last
end

return expr
