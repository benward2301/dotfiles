return {
  'rcarriga/nvim-notify',
  event = 'VeryLazy',
  config = function()
    local notify = require 'notify'
    notify.setup {
      fps = 60,
      level = 2,
      max_width = 50,
      minimum_width = 1,
      render = 'minimal',
      stages = 'fade',
      timeout = 5000,
      top_down = false,
    }

    vim.notify = function(msg, level, opts)
      vim.schedule(function() notify(msg, level, opts) end)
    end

  end,
}
