vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.sidescroll = 1
vim.o.sidescrolloff = 8
vim.o.confirm = true

vim.o.autoindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 0
vim.o.shiftwidth = 0
vim.o.linebreak = true
vim.o.wrap= false

vim.o.swapfile = false
vim.opt.guicursor = 'n:block-blinkwait700-blinkoff400-blinkon250,v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50'
