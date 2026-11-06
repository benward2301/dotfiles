#!/usr/bin/env -S nvim -l

local dir = arg[0]:match('^(.*)/[^/]+$') or '.'
package.path = dir .. '/../lua/?.lua;' .. package.path

local devicons = require('utils.devicons')

local function strip_ansi(s)
  return (s:gsub('\27%[[0-9;:]*m', ''))
end

local out = io.stdout
for line in io.lines() do

  local path = strip_ansi(line):match('^([^:]+):%d')
  if path then
    out:write(devicons.ansi(path), ' ', line, '\n')
  else
    out:write(line, '\n')
  end
end
