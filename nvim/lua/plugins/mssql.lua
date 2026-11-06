return {
  'Kurren123/mssql.nvim',
  dependencies = { 'folke/which-key.nvim' },
  event = 'VeryLazy',
  opts = {
    keymap_prefix = '<leader>m',
  },
  config = function(_, opts)
    local mssql = require 'mssql'
    local states = require('mssql.query_manager').states

    local function plugin_opts()
      local i = 1
      while true do
        local name, value = debug.getupvalue(mssql.new_default_query, i)
        if not name then
          return nil
        end
        if name == 'plugin_opts' then
          return value
        end
        i = i + 1
      end
    end

    local function show_schema(qm, item)
      local meta = item.metadata
      local function esc(str)
        return (str:gsub("'", "''"))
      end
      local query
      if item.objectType == 'Table' or item.objectType == 'View' then
        query = ([[
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'
ORDER BY ORDINAL_POSITION]]):format(esc(meta.schema or 'dbo'), esc(meta.name))
      else
        local name = meta.schema and ('[%s].[%s]'):format(meta.schema, meta.name) or ('[%s]'):format(meta.name)
        query = ("EXEC sp_help N'%s'"):format(esc(name))
      end

      local lines = vim.split(query, '\n')
      local buf = vim.api.nvim_get_current_buf()
      if vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false))) == '' then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      else
        table.insert(lines, 1, '')
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
      end

      require('mssql.utils').try_resume(coroutine.create(function()
        local result = qm.execute_async(query)
        local resolved = plugin_opts()
        if not resolved then
          return vim.notify('mssql: could not find plugin options', vim.log.levels.ERROR)
        end
        if result then
          require 'mssql.display_query_results'(resolved, result)
        end
      end))
    end

    local function find_with_schema()
      local qm = vim.b.query_manager
      local orig = vim.ui.select
      vim.ui.select = function(items, ui_opts, on_choice)
        vim.ui.select = orig
        if items[1] and items[1].metadata and items[1].objectType then
          ui_opts = vim.tbl_extend('force', ui_opts or {}, {
            fzf_actions = {
              ['ctrl-x'] = function(selected, o)
                local idx = tonumber(selected[1]:match '^%s*(%d+)%.')
                local item = idx and o._items[idx]
                if item then
                  vim.schedule(function()
                    show_schema(qm, item)
                  end)
                end
              end,
            },
          })
        end
        return orig(items, ui_opts, on_choice)
      end
      mssql.find_object()
    end

    local function find()
      if vim.b.query_manager then
        return find_with_schema()
      end
      mssql.new_default_query()
      local ready_polls, elapsed = 0, 0
      local timer = assert(vim.uv.new_timer())
      timer:start(
        200,
        200,
        vim.schedule_wrap(function()
          elapsed = elapsed + 200
          local qm = vim.b.query_manager
          if qm and qm.get_state() == states.Connected and not qm.is_refreshing() then
            ready_polls = ready_polls + 1
          else
            ready_polls = 0
          end
          if ready_polls >= 2 then
            timer:close()
            find_with_schema()
          elseif elapsed >= 120000 then
            timer:close()
            vim.notify('mssql: timed out waiting for connection', vim.log.levels.WARN)
          end
        end)
      )
    end

    mssql.setup(opts, function()
      vim.keymap.set('n', opts.keymap_prefix .. 'f', find, { desc = 'Find' })
    end)
    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = vim.api.nvim_create_augroup('mssql_results_nowrap', { clear = true }),
      callback = function(ev)
        if vim.b[ev.buf].query_result_info then
          vim.wo.wrap = false
        end
      end,
    })
  end,
}
