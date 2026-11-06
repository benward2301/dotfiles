return {
  'saghen/blink.cmp',
  event = { 'InsertEnter', 'CmdlineEnter' },
  version = '1.*',
  dependencies = {

    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()

        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {

      },
      opts = {},
    },
    'folke/lazydev.nvim',
  },

  opts = {
    keymap = {

      preset = 'default',
      ['<C-o>'] = { 'select_and_accept' },
      ['<Tab>'] = { 'select_next', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
    },

    cmdline = {
      keymap = { preset = 'inherit' },
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = false, auto_insert = true } },
      },
    },

    appearance = {

      nerd_font_variant = 'mono',
    },

    completion = {

      documentation = { auto_show = false, auto_show_delay_ms = 500 },
      list = {

        selection = { preselect = false, auto_insert = true },
        cycle = { from_bottom = true },
      },
      menu = {
        draw = {
          padding = { 1, 1 },
          components = {
            kind_icon = {
              ellipsis = false
            },
          },
        },
      },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        lsp = {
          -- mssql_ls sends JSON nulls (vim.NIL) for filterText/sortText, which the lua fuzzy matcher can't handle
          transform_items = function(_, items)
            for _, item in ipairs(items) do
              for k, v in pairs(item) do
                if v == vim.NIL then
                  item[k] = nil
                end
              end
            end
            return items
          end,
        },
      },
    },

    snippets = { preset = 'luasnip' },

    fuzzy = { implementation = 'lua' },

    signature = { enabled = true },
  },
}
