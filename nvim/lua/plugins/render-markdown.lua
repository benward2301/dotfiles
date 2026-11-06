return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' },
  keys = {
    { '<leader>tm', ':RenderMarkdown buf_toggle<CR>', desc = 'toggle render-markdown' },
  },
  opts = {
    sign = { enabled = false },
    heading = {
      icons = {},
      sign = false,
      width = 'block',
      backgrounds = {},
    },
    code = {
      width = 'block',
      language = false,
      left_pad = 2,
      right_pad = 2,
      border = 'thin',
      inline_pad = 1,
    },
    bullet = {
      icons = { '•', '◦', '▪', '▫' },
    },
    anti_conceal = {
      enabled = false,
    },
  },
  config = function(_, opts)
    require('render-markdown').setup(opts)

    local foxglove = require 'foxglove'
    local function heading(p)
      return { fg = p.cyan1, bold = true }
    end
    local function strong(p)
      return { fg = p.text1, bold = true }
    end
    foxglove.highlight('@markup.heading', heading)
    for level = 1, 6 do
      foxglove.highlight(('@markup.heading.%d.markdown'):format(level), heading)
    end
    foxglove.highlight('@markup.strong', strong)
    foxglove.highlight('@markup.strong.markdown_inline', strong)
    foxglove.highlight('@markup.italic', function(p)
      return { fg = p.text1, italic = true }
    end)
    foxglove.highlight('@markup.raw.markdown_inline', function(p)
      return { fg = p.red1, italic = false }
    end)
  end,
}
