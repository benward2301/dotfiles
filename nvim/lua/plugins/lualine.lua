return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  cond = function()
    return not vim.g.term_scratch
  end,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.opt.shortmess:append 'S'

    local function is_wide_window()
      return vim.fn.winwidth(0) > 80
    end

    local function palette()
      return require('foxglove').palette()
    end

    local function section(p, accent)
      return {
        a = { fg = p.base1, bg = accent, gui = 'bold' },
        b = { fg = p.text1, bg = p.base4 },
        c = { fg = p.text2, bg = p.base0 },
        x = { fg = p.subtext1, bg = p.base0 },
        y = { fg = p.text1, bg = p.base4 },
        z = { fg = p.base1, bg = p.text1, gui = 'bold' },
      }
    end

    local function theme()
      local p = palette()
      if not p then
        return 'auto'
      end
      local dim = { fg = p.subtext1, bg = p.base0 }
      return {
        normal = section(p, p.blue1),
        insert = section(p, p.green1),
        terminal = section(p, p.green1),
        visual = section(p, p.magenta1),
        replace = section(p, p.red1),
        command = section(p, p.yellow1),
        inactive = { a = dim, b = dim, c = dim, x = dim, y = dim, z = dim },
      }
    end

    local function diff_colors()
      local p = palette()
      if not p then
        return
      end
      vim.api.nvim_set_hl(0, 'LuaLineDiffAdd', { fg = p.green2 })
      vim.api.nvim_set_hl(0, 'LuaLineDiffChange', { fg = p.blue2 })
      vim.api.nvim_set_hl(0, 'LuaLineDiffRemove', { fg = p.red2 })
    end

    diff_colors()

    require('lualine').setup {
      options = {
        theme = theme,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        icons_enabled = true,
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              str = string.gsub(str, 'V%-', '')

              if vim.fn.winwidth(0) <= 80 then
                return str:sub(1, 3)
              end
              return str
            end,
          },
        },
        lualine_b = {
          {
            'branch',
            cond = is_wide_window,
            icon = { '' },
            fmt = function(str)
              if #str > 20 then
                return str:sub(1, 25)
              end
              return str
            end,
          },
        },
        lualine_c = {
          {
            'filetype',
            icon_only = true,
            padding = { left = 1, right = 0 },
            colored = true,
            fmt = function(str)
              if str == '' then
                return ' '
              end
              return str
            end,
          },
          {
            'filename',
            path = 1,
            shorting_target = 50,
            padding = { left = 0, right = 1 },
          },
        },
        lualine_x = {
          {
            'diagnostics',
            cond = is_wide_window,
            sections = { 'hint', 'info', 'warn', 'error' },
            symbols = { hint = ' ', info = '󰋽 ', warn = '󰀪 ', error = '󰅚 ' },
          },
          {
            'lsp_status',
            cond = is_wide_window,
          },
          {
            'diff',
            cond = is_wide_window,
            symbols = {
              added = ' ',
              modified = ' ',
              removed = ' ',
            },
          },
        },
        lualine_y = {
          {
            'progress',
            cond = is_wide_window,
            padding = { left = 1, right = 1 },
          },
          {
            'searchcount',
            padding = { left = 0, right = 1 },
          },
        },
        lualine_z = {
          {
            'location',
            cond = is_wide_window,
            padding = { left = 1, right = 1 },
          },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_c = {
          {
            'filetype',
            icon_only = true,
            padding = { left = 1, right = 0 },
            colored = false,
            fmt = function(str)
              if str == '' then
                return ' '
              end
              return str
            end,
          },
          {
            'filename',
            path = 1,
            shorting_target = 50,
            padding = { left = 0, right = 1 },
          },
        },
        lualine_b = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    }

    local applied
    vim.api.nvim_create_autocmd('User', {
      pattern = 'FoxgloveRendered',
      callback = function()
        local built = theme()
        if vim.deep_equal(built, applied) then
          return
        end
        applied = built
        diff_colors()
        require('lualine').setup()
      end,
    })
  end,
}
