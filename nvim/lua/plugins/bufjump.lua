return {
  'kwkarlwang/bufjump.nvim',
  event = 'VeryLazy',
  config = function()
    require('bufjump').setup {
      forward_key = '<C-.>',
      backward_key = '<C-,>',
    }
  end,
}
