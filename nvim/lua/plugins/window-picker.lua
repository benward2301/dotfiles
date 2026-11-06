return {
  's1n7ax/nvim-window-picker',
  name = 'window-picker',
  event = 'VeryLazy',
  version = '2.*',
  config = function()
    require('window-picker').setup {
      filter_rules = {
        bo = {
          filetype = { 'OverseerList', 'Outline', 'neo-tree', 'notify' },
          buftype = {},
        },
      },
      include_current_win = true,
    }

    vim.keymap.set('n', 'gf', function()
      local filepath = vim.fn.expand '<cfile>'
      local picked_window_id = require('window-picker').pick_window()
      if picked_window_id then
        vim.api.nvim_set_current_win(picked_window_id)
        vim.cmd('e ' .. filepath)
      end
    end, { desc = 'go to file in picked window' })
  end,
}
