return {
  'declancm/cinnamon.nvim',
  event = 'VeryLazy',
  config = function()
    local cinnamon = require 'cinnamon'
    cinnamon.setup {
      keymaps = { basic = false, extra = false },
      options = { delay = 3 },
    }

    local function map(modes, lhs, cmd, opts)
      vim.keymap.set(modes, lhs, function()
        cinnamon.scroll(cmd or lhs, opts)
      end, { desc = 'smooth ' .. (cmd or lhs) })
    end

    -- vertical scrolling
    for _, k in ipairs { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<PageUp>', '<PageDown>', 'zt', 'zz', 'zb' } do
      map({ 'n', 'x' }, k)
    end
    for _, k in ipairs { '<C-y>', '<C-e>' } do
      map({ 'n', 'x' }, k, nil, { count_only = true })
    end

    -- horizontal scrolling
    for _, k in ipairs { 'zH', 'zL', 'zs', 'ze' } do
      map({ 'n', 'x' }, k)
    end
    for _, k in ipairs { 'zh', 'zl' } do
      map({ 'n', 'x' }, k, nil, { count_only = true })
    end
    map({ 'n', 'x' }, '<C-h>', 'zH')
    map({ 'n', 'x' }, '<C-l>', 'zL')
  end,
}
