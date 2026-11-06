return {
  'echasnovski/mini.nvim',
  mini = true,
  config = function()
    require('mini.ai').setup { n_lines = 500 }

  end,
}
