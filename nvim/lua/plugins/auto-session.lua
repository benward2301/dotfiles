return {
  'rmagatti/auto-session',
  event = 'VeryLazy',
  config = function()

    local function is_neo_tree(buf)
      return vim.bo[buf].filetype == 'neo-tree'
        or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'):match '^neo%-tree .+%[%d+%]$' ~= nil
    end

    local function is_phantom_neo_tree(buf)
      return vim.bo[buf].filetype ~= 'neo-tree'
        and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'):match '^neo%-tree .+%[%d+%]$' ~= nil
    end

    local function is_real_file(buf)
      return vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ''
        and vim.api.nvim_buf_get_name(buf) ~= ''
        and not is_phantom_neo_tree(buf)
    end

    require('auto-session').setup {
      suppressed_dirs = { '~/' },
      auto_restore = false,
      bypass_save_filetypes = { '', 'alpha', 'neo-tree' },

      pre_save_cmds = {
        function()
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
              local buf = vim.api.nvim_win_get_buf(win)
              if is_neo_tree(buf) and #vim.api.nvim_tabpage_list_wins(tab) > 1 then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end
          end
        end,
      },

      post_restore_cmds = {
        function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if is_phantom_neo_tree(vim.api.nvim_win_get_buf(win)) then
              local target = vim.fn.bufnr '#'
              if not (target > 0 and is_real_file(target)) then
                target = nil
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                  if is_real_file(buf) then
                    target = buf
                    break
                  end
                end
              end
              if target then
                vim.api.nvim_win_set_buf(win, target)
              end
            end
          end

          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if is_phantom_neo_tree(buf) or vim.api.nvim_buf_get_name(buf):match '^term://' then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end,
      },
    }
  end,
}
