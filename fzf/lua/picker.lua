#!/usr/bin/env -S nvim -l

local script = arg[0]
local dir = script:match('^(.*)/[^/]+$') or '.'
package.path = dir .. '/?.lua;' .. package.path

local json = require('utils.json')

local function die(msg)
  io.stderr:write('picker.lua: ' .. msg .. '\n')
  os.exit(1)
end

local function valid_name(name)
  return name and name:match('^[%w_]+$') ~= nil
end

local function picker_path(name)
  return dir .. '/pickers/' .. name .. '.lua'
end

local function load_picker(name)
  if not valid_name(name) then die('invalid picker name') end
  local f = io.open(picker_path(name))
  if not f then die('unknown picker: ' .. tostring(name)) end
  f:close()
  return require('pickers.' .. name)
end

local function read_records()
  local lines, records = {}, {}
  for line in io.lines() do
    if line:match('%S') then
      local ok, rec = pcall(json.decode, line)
      if ok and type(rec) == 'table' then
        lines[#lines + 1] = line
        records[#records + 1] = rec
      end
    end
  end
  return lines, records
end

local commands = {}

function commands.list()
  local p = io.popen('ls "' .. dir .. '/pickers" 2>/dev/null')
  if not p then return end
  for entry in p:lines() do
    local name = entry:match('^(.+)%.lua$')
    if name then io.write(name, '\n') end
  end
  p:close()
end

function commands.exists(name)
  if not valid_name(name) then os.exit(1) end
  local f = io.open(picker_path(name))
  if f then f:close(); os.exit(0) end
  os.exit(1)
end

function commands.meta(name)
  local p = load_picker(name)
  local out = p.output
  local meta = {
    command = p.command,
    format = p.format,
    shell_quote = p.shell_quote == true,
    smart_cursor = p.smart_cursor ~= false,
    no_space_accept = p.no_space_accept == true,
    fields_count = p.fields and #p.fields or 0,
    has_input = type(p.input) == 'function',
    has_preview = type(p.preview) == 'function',
    has_output = out ~= nil,
    has_copy = type(p.copy) == 'function',
    options = p.options or {},
    eval = p.eval or {},
  }

  if type(out) == 'string' then meta.output = out end
  io.write(json.encode(meta), '\n')
end

function commands.format(name)
  local p = load_picker(name)
  local format = require('utils.format')
  local lines, records = read_records()
  local display = format.format_all(p, records)
  local buf = {}
  for i = 1, #records do
    buf[#buf + 1] = lines[i] .. '\t' .. (display[i] or '')
  end
  if #buf > 0 then io.write(table.concat(buf, '\n'), '\n') end
end

function commands.run(name)
  local p = load_picker(name)
  if type(p.input) ~= 'function' then die('picker has no input function: ' .. name) end
  local rows = p.input() or {}
  local buf = {}
  if p.fields and #p.fields > 0 then
    local format = require('utils.format')
    local display = format.format_all(p, rows)
    for i = 1, #rows do
      buf[#buf + 1] = json.encode(rows[i]) .. '\t' .. (display[i] or '')
    end
  else
    for _, line in ipairs(rows) do buf[#buf + 1] = tostring(line) end
  end
  if #buf > 0 then io.write(table.concat(buf, '\n'), '\n') end
end

function commands.preview(name, record_arg)
  local p = load_picker(name)
  if type(p.preview) ~= 'function' then return end
  local r
  if p.format == 'json' then
    local ok, dec = pcall(json.decode, record_arg or '')
    r = (ok and type(dec) == 'table') and dec or {}
  else
    r = record_arg or ''
  end
  local out = p.preview(r)
  if out ~= nil then io.write(tostring(out)) end
end

function commands.apply(name, which, ...)
  local p = load_picker(name)
  local flags = { ... }
  local print0 = false
  for _, fl in ipairs(flags) do
    if fl == '--print0' then print0 = true end
  end
  local fn
  if which == 'copy' then
    fn = type(p.copy) == 'function' and p.copy or p.output
  else
    fn = p.output
  end
  if type(fn) ~= 'function' then os.exit(0) end

  local sep = print0 and '\0' or '\n'
  local _, records = read_records()
  for _, rec in ipairs(records) do
    local ok, val = pcall(fn, rec)
    local out = (ok and val ~= nil) and tostring(val) or ''
    io.write(out, sep)
  end
end

local mode = arg[1]
if mode == '--list' then
  commands.list()
elseif mode == '--exists' then
  commands.exists(arg[2])
elseif mode == '--meta' then
  commands.meta(arg[2])
elseif mode == '--run' then
  commands.run(arg[2])
elseif mode == '--format' then
  commands.format(arg[2])
elseif mode == '--preview' then
  commands.preview(arg[2], arg[3])
elseif mode == '--apply' then
  commands.apply(arg[2], arg[3], select(4, (table.unpack or unpack)(arg)))
else
  die('usage: picker.lua --list|--exists|--meta|--run|--format|--preview|--apply NAME ...')
end
