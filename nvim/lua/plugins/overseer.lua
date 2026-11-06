return {
  'stevearc/overseer.nvim',
  event = 'VeryLazy',
  config = function()
    local map = vim.keymap.set
    local nv = { 'n', 'v' }

    require('overseer').setup {
      task_list = {
        default_detail = 1,
        bindings = {
          ['<C-q>'] = 'OpenQuickFix',
          ['<C-x>'] = 'OpenSplit',
          ['K'] = 'PrevTask',
          ['J'] = 'NextTask',
        },
      },
      component_aliases = {
        default = {
          { 'display_duration', detail_level = 2 },
          'on_output_summarize',
          'on_exit_set_status',
          'on_complete_notify',
          { 'on_complete_dispose', require_view = { 'SUCCESS', 'FAILURE' } },
          { 'open_output', on_start = 'always', direction = 'dock', focus = false },
        },
      },
    }

    map('n', '<leader>:', ':OverseerRunCmd ', { desc = 'overseer: run command' })
    map('n', '<leader>o', function()
      require('overseer').run_template {}
    end, { desc = 'overseer: run task' })
    map('n', '<leader>O', ':OverseerOpen<CR>', { desc = 'open overseer' })
    map(nv, 'gor', '<cmd>OverseerQuickAction restart<CR>', { desc = 'overseer: restart task' })
    map(nv, 'gov', '<cmd>OverseerQuickAction open vsplit<CR>', { desc = 'overseer: open task in vsplit' })
    map(nv, 'gox', '<cmd>OverseerQuickAction open hsplit<CR>', { desc = 'overseer: open task in hsplit' })
    map(nv, 'gof', '<cmd>OverseerQuickAction open float<CR>', { desc = 'overseer: open task in float' })
    map(nv, 'goo', '<cmd>OverseerQuickAction open<CR>', { desc = 'overseer: open task in current window' })
    map(nv, 'got', '<cmd>OverseerQuickAction open tab<CR>', { desc = 'overseer: open task in tab' })
    map(
      'n',
      'goq',
      ':OverseerQuickAction open output in quickfix<CR>:cc<CR>',
      { desc = 'overseer: open task quickfix list' }
    )

  end,
}
