local xdg_config = os.getenv 'XDG_CONFIG_HOME' or (os.getenv 'HOME' .. '/.config')

return {
  'benward2301/foxglove.nvim',
  lazy = false,
  priority = 1000,
  mini = true,
  config = function()
    local highlight = require('foxglove').highlight

    require('foxglove').setup {
      maps = {
        move_down = { '<Tab>', '<C-j>', '<C-n>' },
        move_up = { '<S-Tab>', '<C-k>', '<C-p>' },
        next_tab = { '<M-n>' },
      },
    }

    vim.api.nvim_create_autocmd('User', {
      pattern = 'FoxgloveThemeChanged',
      callback = function(ev)
        local name = ev.data.theme.palette
        local palette_changed = not ev.data.previous or ev.data.previous.palette ~= name
        if palette_changed then
          require('artifacts').write(name, require('foxglove').palette())
        end
        vim.system({ xdg_config .. '/foxglove/apply.sh' }, { detach = true })
      end,
    })

    local function pmenu_match_color(p)
      return p.name == 'carbon-light' and '#eb6200' or p.name == 'carbonfox' and '#ffb784' or nil
    end

    highlight('PmenuMatch', function(p)
      local fg = pmenu_match_color(p)
      return fg and { fg = fg } or nil
    end)

    highlight('AlphaHeader', function(p)
      local fg = pmenu_match_color(p)
      return fg and { fg = fg } or { link = '@number' }
    end)

    highlight('QuickScopePrimary', function(p)
      return {
        sp = pmenu_match_color(p) or p.yellow0,
        underline = true,
      }
    end)
    highlight('QuickScopeSecondary', function(p)
      return {
        sp = pmenu_match_color(p) or p.yellow0,
        underdouble = true,
      }
    end)
  end,
}
