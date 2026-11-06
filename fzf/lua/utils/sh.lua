
local sh = {}

function sh.shquote(s)
  return "'" .. tostring(s):gsub("'", [['\'']]) .. "'"
end

function sh.trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

function sh.split(s, sep)
  local out, i = {}, 1
  while true do
    local j = s:find(sep, i, true)
    if not j then out[#out + 1] = s:sub(i); break end
    out[#out + 1] = s:sub(i, j - 1)
    i = j + #sep
  end
  return out
end

function sh.run(cmd)
  local p = io.popen(cmd)
  if not p then return '' end
  local out = p:read('*a') or ''
  p:close()
  return out
end

function sh.ok(cmd)

  local ok = os.execute(cmd)
  if type(ok) == 'number' then return ok == 0 end
  return ok == true
end

function sh.lines(cmd)
  local out = sh.run(cmd)
  if out == '' then return {} end
  out = out:gsub('\n$', '')
  if out == '' then return {} end
  return sh.split(out, '\n')
end

return sh
