return {
  'mbbill/undotree',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set('n', '<leader>U', ':UndotreeShow<CR>:UndotreeFocus<CR>', { desc = 'open undotree' })
  end,
}
