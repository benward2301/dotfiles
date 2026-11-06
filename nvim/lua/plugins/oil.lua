return {
  'stevearc/oil.nvim',
  opts = {},
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,
  tag = 'v2.15.0',
  config = function()

    require('oil').setup {
      view_options = {
        is_hidden_file = function(name)
          return name:match '^%..$' or name == '.git'
        end,
      },
      use_default_keymaps = false,
      keymaps = {
        ['g?'] = { 'actions.show_help', mode = 'n' },
        ['<CR>'] = 'actions.select',
        ['<C-R>'] = 'actions.refresh',
        ['gs'] = { 'actions.change_sort', mode = 'n' },
        ['g.'] = { 'actions.toggle_hidden', mode = 'n' },
        ['g\\'] = { 'actions.toggle_trash', mode = 'n' },
      },
      float = {
        get_win_title = function()
          return ''
        end,
        max_width = 0.4,
        max_height = 0.8,
        border = 'solid',
      },
    }
  end,
}
