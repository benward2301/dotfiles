
local json = {}

local array_mt = {}

function json.array(t)
  return setmetatable(t or {}, array_mt)
end

local decode_value

local escape_in = {
  ['"'] = '"', ['\\'] = '\\', ['/'] = '/',
  b = '\b', f = '\f', n = '\n', r = '\r', t = '\t',
}

local function skip_ws(s, i)
  local _, j = s:find('^[ \t\r\n]*', i)
  return j + 1
end

local function decode_error(s, i, msg)
  error(('json: %s at position %d'):format(msg, i))
end

local function codepoint_to_utf8(n)
  if n < 0x80 then
    return string.char(n)
  elseif n < 0x800 then
    return string.char(0xC0 + math.floor(n / 0x40), 0x80 + n % 0x40)
  elseif n < 0x10000 then
    return string.char(0xE0 + math.floor(n / 0x1000), 0x80 + math.floor(n / 0x40) % 0x40, 0x80 + n % 0x40)
  else
    return string.char(0xF0 + math.floor(n / 0x40000), 0x80 + math.floor(n / 0x1000) % 0x40,
      0x80 + math.floor(n / 0x40) % 0x40, 0x80 + n % 0x40)
  end
end

local function decode_string(s, i)

  local parts = {}
  i = i + 1
  while true do
    local c = s:sub(i, i)
    if c == '' then decode_error(s, i, 'unterminated string') end
    if c == '"' then
      return table.concat(parts), i + 1
    elseif c == '\\' then
      local e = s:sub(i + 1, i + 1)
      if e == 'u' then
        local hex = s:sub(i + 2, i + 5)
        local n = tonumber(hex, 16)
        if not n then decode_error(s, i, 'invalid \\u escape') end

        if n >= 0xD800 and n <= 0xDBFF then
          local hex2 = s:sub(i + 8, i + 11)
          local n2 = s:sub(i + 6, i + 7) == '\\u' and tonumber(hex2, 16)
          if n2 and n2 >= 0xDC00 and n2 <= 0xDFFF then
            n = 0x10000 + (n - 0xD800) * 0x400 + (n2 - 0xDC00)
            i = i + 6
          end
        end
        parts[#parts + 1] = codepoint_to_utf8(n)
        i = i + 6
      else
        local m = escape_in[e]
        if not m then decode_error(s, i, 'invalid escape \\' .. e) end
        parts[#parts + 1] = m
        i = i + 2
      end
    else
      parts[#parts + 1] = c
      i = i + 1
    end
  end
end

local function decode_number(s, i)
  local _, j = s:find('^-?%d+%.?%d*[eE]?[+-]?%d*', i)
  local num = tonumber(s:sub(i, j))
  if not num then decode_error(s, i, 'invalid number') end
  return num, j + 1
end

local function decode_array(s, i)
  local arr, n = setmetatable({}, array_mt), 0
  i = skip_ws(s, i + 1)
  if s:sub(i, i) == ']' then return arr, i + 1 end
  while true do
    local v
    v, i = decode_value(s, i)
    n = n + 1
    arr[n] = v
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == ']' then return arr, i + 1 end
    if c ~= ',' then decode_error(s, i, "expected ',' or ']'") end
    i = skip_ws(s, i + 1)
  end
end

local function decode_object(s, i)
  local obj = {}
  i = skip_ws(s, i + 1)
  if s:sub(i, i) == '}' then return obj, i + 1 end
  while true do
    if s:sub(i, i) ~= '"' then decode_error(s, i, 'expected string key') end
    local key
    key, i = decode_string(s, i)
    i = skip_ws(s, i)
    if s:sub(i, i) ~= ':' then decode_error(s, i, "expected ':'") end
    local v
    v, i = decode_value(s, skip_ws(s, i + 1))
    obj[key] = v
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == '}' then return obj, i + 1 end
    if c ~= ',' then decode_error(s, i, "expected ',' or '}'") end
    i = skip_ws(s, i + 1)
  end
end

function decode_value(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == '{' then return decode_object(s, i)
  elseif c == '[' then return decode_array(s, i)
  elseif c == '"' then return decode_string(s, i)
  elseif c == 't' then
    if s:sub(i, i + 3) == 'true' then return true, i + 4 end
  elseif c == 'f' then
    if s:sub(i, i + 4) == 'false' then return false, i + 5 end
  elseif c == 'n' then
    if s:sub(i, i + 3) == 'null' then return nil, i + 4 end
  elseif c == '-' or c:match('%d') then
    return decode_number(s, i)
  end
  decode_error(s, i, 'unexpected character ' .. (c == '' and '<eof>' or c))
end

function json.decode(s)
  local v, i = decode_value(s, 1)
  i = skip_ws(s, i)
  if i <= #s then decode_error(s, i, 'trailing characters') end
  return v
end

local escape_out = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function encode_string(s)
  return '"' .. s:gsub('[%z\1-\31"\\]', function(c)
    return escape_out[c] or ('\\u%04x'):format(c:byte())
  end) .. '"'
end

local function encode_number(n)

  if n % 1 == 0 and n > -2 ^ 63 and n < 2 ^ 63 then
    return ('%d'):format(n)
  end
  return ('%.14g'):format(n)
end

local encode_value

local function is_array(t)
  if getmetatable(t) == array_mt then return true end
  local n = 0
  for k in pairs(t) do
    if type(k) ~= 'number' or k % 1 ~= 0 or k < 1 then return false end
    n = n + 1
  end
  return n == #t and n > 0
end

local function encode_table(t)
  if is_array(t) then
    local parts = {}
    for idx = 1, #t do
      parts[idx] = encode_value(t[idx])
    end
    return '[' .. table.concat(parts, ',') .. ']'
  end
  local parts, n = {}, 0
  for k, v in pairs(t) do
    n = n + 1
    parts[n] = encode_string(tostring(k)) .. ':' .. encode_value(v)
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

function encode_value(v)
  local ty = type(v)
  if ty == 'string' then return encode_string(v)
  elseif ty == 'number' then return encode_number(v)
  elseif ty == 'boolean' then return v and 'true' or 'false'
  elseif ty == 'table' then return encode_table(v)
  elseif ty == 'nil' then return 'null'
  end
  error('json: cannot encode ' .. ty)
end

function json.encode(v)
  return encode_value(v)
end

return json
