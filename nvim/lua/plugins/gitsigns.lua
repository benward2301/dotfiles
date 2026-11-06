return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '-' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
  },
  config = function(_, opts)
    local gs = require 'gitsigns'

    gs.setup(opts)

    local map = vim.keymap.set

    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gs.nav_hunk 'next'
      end
    end, { desc = 'next git change' })
    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gs.nav_hunk 'prev'
      end
    end, { desc = 'prev git change' })

    map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
    map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
    map('v', '<leader>hs', function()
      gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'git stage hunk' })
    map('v', '<leader>hr', function()
      gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'git reset hunk' })
    map('n', '<leader>hS', gs.stage_buffer, { desc = 'git stage buffer' })
    map('n', '<leader>hR', gs.reset_buffer, { desc = 'git reset buffer' })
    map('n', '<leader>hp', gs.preview_hunk, { desc = 'git preview hunk' })
    map('n', '<leader>hi', gs.preview_hunk_inline, { desc = 'git preview hunk inline' })
    map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
    map('n', '<leader>hD', function()
      gs.diffthis '@'
    end, { desc = 'git diff against last commit' })
    map('n', '<leader>hk', function()
      gs.setqflist 'all'
    end, { desc = 'git quickfix hunk' })
    map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
    map({ 'o', 'x' }, 'ih', gs.select_hunk, { desc = 'git select hunk' })

  end,
}
