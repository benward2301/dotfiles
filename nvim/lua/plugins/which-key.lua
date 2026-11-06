return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    delay = 1000,
    icons = {
      mappings = vim.g.have_nerd_font,
    },
    spec = {
      { '<leader>t', group = 'toggle' },
      { '<leader>h', group = 'git hunk', mode = { 'n', 'v' } },
    },
  },
  keys = {
    {
      '<leader>?',
      function()
        require('which-key').show { global = false }
      end,
      desc = 'Show local keymaps',
    },
  },
  config = function(_, opts)
    require('which-key').setup(opts)
  end,
}
