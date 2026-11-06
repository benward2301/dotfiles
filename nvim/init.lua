
vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require 'options'

package.path = (os.getenv 'XDG_CONFIG_HOME' or os.getenv 'HOME' .. '/.config')
  .. '/foxglove/lua/?.lua;' .. package.path

require 'autocmds'
require 'keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

local specs
if vim.g.mini then
  vim.o.laststatus = 0
  specs = {}
  local dir = vim.fn.stdpath 'config' .. '/lua/plugins'
  for _, path in ipairs(vim.fn.glob(dir .. '/*.lua', false, true)) do
    local mod = 'plugins.' .. vim.fn.fnamemodify(path, ':t:r')
    local spec = require(mod)
    if spec.mini then
      specs[#specs + 1] = spec
    end
  end
else
  specs = { { import = 'plugins' } }
end

require('lazy').setup(specs, {

  dev = { path = '~/code/lua', fallback = true },

  local_spec = false,
})
