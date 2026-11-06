#!/usr/bin/env -S nvim -l

local dir = arg[0]:match('^(.*)/[^/]+$') or '.'
package.path = dir .. '/../lua/?.lua;' .. package.path

local devicons = require('utils.devicons')
local colors = require('utils.colors')

local home = (os.getenv('HOME') or '') .. '/'
local hlen = #home
local is_dir = arg[1] == 'dir'

local out = io.stdout
for line in io.lines() do
  if line ~= '' then
    local disp = line:sub(1, hlen) == home and line:sub(hlen + 1) or line
    if is_dir then
      out:write(line, '\t', colors.split_dir(disp, 'subtext0', 'text1'), '\n')
    else
      out:write(line, '\t', is_dir and line or devicons.ansi(line), ' ', colors.dim_dir(disp, 'subtext0'), '\n')
    end
  end
end
