return {
  'sindrets/diffview.nvim',
  event = 'VeryLazy',
  cmd = {
    'DiffviewOpen',
    'DiffviewFileHistory',
    'DiffviewClose',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
  },
  config = function()
    local actions = require 'diffview.actions'
    local is_panel_focused = function()
      return not not string.match(vim.fn.expand '%', '^diffview.*Panel$')
    end
    local diffview_common_keymap = {
      {
        'n',
        's',
      },
      {
        'n',
        'S',
      },
      {
        'n',
        '\\',
        function(...)
          if is_panel_focused() then
            vim.api.nvim_input '<C-w>W'
          else
            actions.focus_files(...)
          end
        end,
        { desc = 'Bring focus to the file panel' },
      },
      {
        'n',
        '<leader>e',
        function(...)
          actions.toggle_files(...)
          if is_panel_focused() then
            vim.cmd 'wincmd p'
          end
        end,
        { desc = 'Toggle the file panel' },
      },
      {
        'n',
        'C',
        function()
          vim.api.nvim_input 'zc'
        end,
      },
      {
        'n',
        '<C-j>',
        function()
          if is_panel_focused() then
            vim.api.nvim_input '<C-w>W'
          end
          vim.schedule(function()
            vim.api.nvim_input ']c'
          end)
        end,
      },
      {
        'n',
        '<C-k>',
        function()
          if is_panel_focused() then
            vim.api.nvim_input '<C-w>W'
          end
          vim.schedule(function()
            vim.api.nvim_input '[c'
          end)
        end,
      },
    }

    require('diffview').setup {
      file_panel = {
        win_config = {
          position = 'bottom',
          height = 20,
        },
      },
      keymaps = {
        view = diffview_common_keymap,
        file_panel = diffview_common_keymap,
        file_history_panel = diffview_common_keymap,
      },
      hooks = {
        view_opened = function()
          if vim.g.diffview_replace_tab then
            vim.g.diffview_replace_tab = nil
            local tabs = vim.api.nvim_list_tabpages()
            if #tabs > 1 then
              vim.api.nvim_set_current_tabpage(tabs[1])
              vim.cmd 'tabclose'
            end
          end
        end,
      },
    }

    vim.keymap.set('n', '<leader>d', ':DiffviewOpen<CR>')

    require('foxglove').highlight('DiffviewDiffDelete', function(p)
      return { fg = p.subtext1 }
    end)
    vim.opt.fillchars:append { diff = '╱' }
  end,
}
