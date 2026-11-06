return {
  'unblevable/quick-scope',
  mini = true,
  event = 'VeryLazy',
  init = function()
    vim.g.qs_delay = 0
  end,
  config = function()
    vim.cmd "let g:qs_buftype_blacklist = ['nofile', 'neo-tree', 'alpha']"

    vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TermOpen' }, {
      callback = function()
        local is_floating = vim.api.nvim_win_get_config(0).relative ~= ''
        local is_non_modifiable = not vim.bo.modifiable
        if is_floating or is_non_modifiable then
          vim.b.qs_local_disable = 1
        else
          vim.b.qs_local_disable = 0
        end
      end,
    })

    vim.cmd 'doautocmd CursorMoved'
  end,
}
