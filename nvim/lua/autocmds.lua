vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'highlight on yank',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('VimLeave', {
  callback = function()
    vim.opt.guicursor = 'a:ver25-blinkon0'
    vim.cmd [[silent !echo -ne "\e[5 q"]]
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit', 'gitrebase' },
  callback = function()
    if vim.fn.getline '.' == '' then
      vim.cmd 'startinsert'
    end
  end,
})

vim.api.nvim_create_autocmd('TabNewEntered', { command = 'tabm', desc = 'put new tab last' })

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  callback = function()
    if vim.bo.buftype == '' then
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_buf_set_mark(0, 'c', row, col, {})
      if vim.bo.buflisted then
        vim.api.nvim_buf_set_mark(0, 'C', row, col, {})
      end
    end
  end,
  desc = 'set mark at latest change',
})
