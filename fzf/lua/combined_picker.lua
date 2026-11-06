#!/usr/bin/env -S nvim -l
local dir = arg[0]:match('^(.*)/[^/]+$') or '.'
package.path = dir .. '/?.lua;' .. package.path
local sh = require('utils.sh')

local FZF_DIR = os.getenv('FZF_DIR') or (dir .. '/..')
local MRU_FILE = os.getenv('__FZF_COMBINED_MRU_FILE')
  or ('/tmp/fzf-combined-mru-' .. sh.trim(sh.run('id -u')))
local mru = {}
local mfh = io.open(MRU_FILE)
if mfh then
  for l in mfh:lines() do
    local n, ts = l:match('^(%S+)%s+(%S+)$')
    if n then mru[n] = tonumber(ts) or 0 end
  end
  mfh:close()
end
local function get_mru(n) return mru[n] or 0 end

local items = {}
for _, l in ipairs(sh.lines('grep -hE ' .. sh.shquote('^_fzf_[a-z_]*\\(')
    .. ' ' .. sh.shquote(FZF_DIR .. '/lib/shell-pickers.sh') .. ' 2>/dev/null')) do
  local name = l:match('_fzf_([a-z_]+)')
  if name then
    items[#items + 1] = { mru = get_mru(name), name = name,
      display = '\27[37m' .. name .. '\27[0m' }
  end
end
for _, name in ipairs(sh.lines('nvim -l ' .. sh.shquote(FZF_DIR .. '/lua/picker.lua') .. ' --list 2>/dev/null')) do
  if name ~= '' then
    items[#items + 1] = { mru = get_mru(name), name = name,
      display = '\27[37m' .. name .. '\27[0m' }
  end
end
table.sort(items, function(a, b)
  if a.mru ~= b.mru then return a.mru > b.mru end
  return a.name < b.name
end)
for _, it in ipairs(items) do
  io.write(it.name, '|', it.display, '\n')
end
