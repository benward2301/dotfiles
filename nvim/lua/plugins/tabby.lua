return {
  'nanozuki/tabby.nvim',
  event = 'VeryLazy',
  config = function()

    local foxglove = require 'foxglove'
    foxglove.highlight('TabbyActive', function(p)
      return { bg = p.base3, fg = p.text1 }
    end)
    foxglove.highlight('TabbyInactive', function(p)
      return { bg = p.base1, fg = p.subtext1 }
    end)
    foxglove.highlight('TabbySep', function(p)
      return { bg = p.base1 }
    end)
    require('tabby').setup {
      line = function(line)
        local entries = {}
        table.insert(entries, { line.spacer(), hl = 'TabbySep' })
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and 'TabbyActive' or 'TabbyInactive'
          table.insert(entries, {
            '',
            tab.number(),
            tab.name() .. ' ',
            hl = hl,
            margin = ' ',
          })
          table.insert(entries, {
            line.sep(' ', 'TabbySep', 'TabbySep'),
            hl = 'TabbySep',
          })
        end)
        table.insert(entries, { line.spacer(), hl = 'TabbySep' })
        return entries
      end,
    }
  end,
}
