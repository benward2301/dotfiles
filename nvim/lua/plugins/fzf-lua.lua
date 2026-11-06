return {
  'ibhagwan/fzf-lua',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    local fzf = require 'fzf-lua'

    local copy_path_action = function(selected)
      if not selected or #selected == 0 then
        return
      end
      local values = {}
      for _, item in ipairs(selected) do
        local path = fzf.path.entry_to_file(item).path
        if path then
          table.insert(values, vim.fn.fnamemodify(path, ':p'))
        else
          table.insert(values, item)
        end
      end
      if #values > 0 then
        local result = table.concat(values, '\n')
        vim.fn.setreg('+', result)
        vim.notify('Copied: ' .. result)
      end
    end

    local saved_guicursor = vim.o.guicursor

    local function make_fzf_keymap(overrides)
      local base = {
        ['tab'] = 'down',
        ['shift-tab'] = 'up',
        ['ctrl-p'] = 'toggle-up',
        ['ctrl-n'] = 'toggle-down',
        ['ctrl-s'] = 'jump',
        ['ctrl-q'] = 'toggle-all',
        ['ctrl-alt-c'] = 'deselect-all',
        ['ctrl-alt-j'] = 'preview-half-page-down',
        ['ctrl-alt-k'] = 'preview-half-page-up',
        ['ctrl-alt-f'] = 'page-down',
        ['ctrl-alt-b'] = 'page-up',
        ['ctrl-alt-d'] = 'page-down',
        ['ctrl-alt-u'] = 'page-up',
        ['alt-a'] = 'first',
        ['alt-e'] = 'last',
        ['change'] = 'first',
        ['space'] = 'accept',
        ['ctrl-o'] = 'accept',
      }
      if overrides then
        for k, v in pairs(overrides) do
          base[k] = v
        end
      end
      return base
    end

    local function backdrop_for(palette)
      if not palette.dark then
        return 95
      end
      if type(palette.base1) ~= 'string' then
        return 70
      end
      local hex = palette.base1:gsub('#', '')
      local r = tonumber(hex:sub(1, 2), 16)
      local g = tonumber(hex:sub(3, 4), 16)
      local b = tonumber(hex:sub(5, 6), 16)
      if not (r and g and b) then
        return 70
      end
      local lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
      local t = math.min(lum / 0.3, 1.0)
      return math.floor(100 * (0.7 + (0.88 - 0.7) * t) + 0.5)
    end

    local function build_fzf_colors()
      local p = require('foxglove').palette() or {}
      local hl = vim.api.nvim_get_hl(0, { name = 'PmenuMatch', link = false })
      local match = hl.fg and string.format('#%06x', hl.fg) or p.text1
      return {
        ['fg'] = '-1',
        ['fg+'] = p.text1,
        ['bg'] = '-1',
        ['bg+'] = p.base2,
        ['hl'] = match,
        ['hl+'] = match,
        ['info'] = p.subtext1,
        ['footer'] = p.subtext1,
        ['marker'] = p.magenta1,
        ['pointer'] = p.red1,
        ['prompt'] = p.cyan0,
        ['spinner'] = p.orange1,
        ['border'] = p.base3,
        ['header'] = p.text2,
      }
    end

    fzf.setup {
      fzf_opts = {
        ['--layout'] = 'reverse',
        ['--style'] = 'minimal',
        ['--multi'] = '',
        ['--info'] = 'default',
      },

      fzf_args = '--header-border=horizontal',
      fzf_colors = build_fzf_colors(),

      hls = { live_prompt = 'Normal' },
      winopts = {
        height = 0.6,
        width = 1.0,
        row = 1.0,
        backdrop = backdrop_for(require('foxglove').palette() or {}),
        preview = {
          layout = 'horizontal',
          horizontal = 'right:50%',
        },
        on_create = function()
          vim.o.guicursor = 'a:ver25'

          vim.api.nvim_create_autocmd('WinLeave', {
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
              vim.schedule(function()
                if vim.api.nvim_win_get_config(0).relative == '' then
                  require('fzf-lua').hide()
                end
              end)
            end,
          })
        end,
        on_close = function()
          vim.o.guicursor = saved_guicursor
        end,
      },
      keymap = {
        builtin = {
          ['ctrl-q'] = false,
          ['ctrl-/'] = 'toggle-preview',
          ['<C-M-j>'] = 'preview-page-down',
          ['<C-M-k>'] = 'preview-page-up',

          ['<C-M-a>'] = 'preview-top',
          ['<C-M-e>'] = 'preview-bottom',
        },
        fzf = make_fzf_keymap(),
      },
      actions = {
        files = {
          ['default'] = fzf.actions.file_edit_or_qf,
          ['alt-y'] = copy_path_action,
          ['ctrl-y'] = copy_path_action,
          ['ctrl-x'] = fzf.actions.file_split,
          ['ctrl-v'] = fzf.actions.file_vsplit,
          ['ctrl-q'] = false,
          ['alt-i'] = { fn = fzf.actions.toggle_ignore, reuse = true, header = false },
          ['alt-r'] = { fn = function() end, reload = true, header = false },
        },
      },
      files = {
        fd_opts = '--type f --hidden --follow --exclude .git',
        cwd_prompt = false,

        formatter = 'path.dirname_first',
      },
      grep = {
        rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e',
        prompt = '󰄾 ',
      },
      lsp = {
        prompt = '󰄾 ',
      },
      git = {
        status = {
          actions = {
            ['default'] = function(selected, opts)
              fzf.actions.file_edit(selected, opts)
              local file = fzf.path.entry_to_file(selected[1], opts).path
              if file then
                local out = vim.fn.system(
                  'git diff -U0 ' .. vim.fn.shellescape(file) .. " | rg -m1 '^@@' | rg -o '\\+\\d+' | rg -o '\\d+'"
                )
                local line = tonumber(vim.trim(out))
                if line and line > 0 then
                  vim.api.nvim_win_set_cursor(0, { line, 0 })
                end
              end
            end,
            ['ctrl-x'] = false,
            ['ctrl-r'] = { fn = fzf.actions.git_reset, reload = true },
          },
        },
        commits = {
          preview = 'git show --format=full --stat --color=always {1}',
          actions = {
            ['enter'] = fzf.actions.git_checkout,
            ['ctrl-y'] = { fn = fzf.actions.git_yank_commit, exec_silent = true, header = false },
            ['ctrl-d'] = false,
            ['ctrl-o'] = function(selected)
              if not selected or #selected == 0 then
                return
              end
              local hash = selected[1]:match '[^ ]+'
              if hash then
                vim.cmd('DiffviewOpen ' .. hash .. '^!')
              end
            end,
          },
        },
      },
      buffers = {
        actions = {
          ['ctrl-x'] = fzf.actions.file_split,
          ['alt-x'] = { fn = fzf.actions.buf_del, reload = true },
        },
      },
      builtin = {
        winopts = {
          height = 1,
          width = 40,
          row = 1,
          col = 0,
          preview = { hidden = 'hidden' },
        },
      },
    }

    fzf.register_ui_select(function(ui_opts, items)
      local results_rows = #items + 3
      local preview_rows = 15
      local total = math.min(results_rows + preview_rows, math.floor(vim.o.lines * 0.8))
      local preview_pct = math.floor(preview_rows / total * 100)
      local opts = {
        winopts = {
          height = total,
          width = 0.4,
          row = 0.4,
          preview = {
            layout = 'vertical',
            vertical = 'down:' .. preview_pct .. '%',
          },
        },
      }
      if ui_opts.fzf_actions then
        opts.actions = ui_opts.fzf_actions
      end
      if ui_opts.prompt and ui_opts.prompt ~= '' then
        opts.prompt = ui_opts.prompt:gsub('[%s:]+$', '') .. ' > '
      end
      if ui_opts.kind == 'overseer_template' then
        opts.prompt = '> '
        opts.winopts.title = ' Tasks '
      end
      return opts
    end)

    vim.keymap.set('n', '<leader>f', fzf.files, { desc = 'search files' })
    vim.keymap.set('n', '<leader>s', fzf.live_grep, { desc = 'live grep' })
    vim.keymap.set('n', '<leader><leader>', fzf.buffers, { desc = 'search buffers' })

    vim.keymap.set('n', '<A-s>', fzf.builtin, { desc = 'search select picker' })

    vim.keymap.set('n', '<C-g><C-r>', fzf.live_grep, { desc = 'live grep' })
    vim.keymap.set('n', '<C-g><C-l>', fzf.git_commits, { desc = 'git commits' })
    vim.keymap.set('n', '<C-g><C-b>', fzf.git_branches, { desc = 'git branches' })
    vim.keymap.set('n', '<C-g><C-m>', fzf.git_status, { desc = 'git status' })

    vim.keymap.set('n', 'gws', fzf.grep_cword, { desc = 'search for word by grep' })
    vim.keymap.set('v', 'gws', fzf.grep_visual, { desc = 'search for selection by grep' })

    vim.keymap.set('n', '<A-c>', function()
      fzf.fzf_exec('fd --type d --hidden --exclude .git', {
        winopts = { title = ' Directories ' },
        actions = {
          ['default'] = function(selected)
            if not selected or #selected == 0 then
              return
            end
            local full_path = vim.fn.fnamemodify(selected[1], ':p'):gsub('/$', '')

            require('neo-tree.command').execute {
              action = 'focus',
              source = 'filesystem',
              reveal_file = full_path,
            }

            vim.defer_fn(function()
              local manager = require 'neo-tree.sources.manager'
              local state = manager.get_state 'filesystem'
              local fs = require 'neo-tree.sources.filesystem'
              if state and state.tree then
                local selected_node = state.tree:get_node(full_path)
                if selected_node and selected_node.type == 'directory' then
                  if not selected_node:is_expanded() then
                    fs.toggle_directory(state, selected_node, nil, true, false)
                  end
                  vim.defer_fn(function()
                    local children = state.tree:get_nodes(selected_node:get_id())
                    if children then
                      for _, child in ipairs(children) do
                        if child.type == 'directory' and not child:is_expanded() then
                          fs.toggle_directory(state, child, nil, true, false)
                        end
                      end
                      vim.defer_fn(function()
                        require('neo-tree.ui.renderer').redraw(state)
                      end, 50)
                    end
                  end, 50)
                end
              end
            end, 50)
          end,
        },
      })
    end, { desc = 'search directories' })

    require('foxglove').highlight('FzfLuaTitle', function(p)
      return { fg = p.base1, bg = p.blue1 }
    end)
    require('foxglove').highlight('FzfLuaPreviewTitle', function(p)
      return { fg = p.base1, bg = p.text1 }
    end)

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('fzflua-palette', { clear = true }),
      desc = 'refresh fzf-lua colors from the new palette',
      callback = function()
        fzf.setup({
          fzf_colors = build_fzf_colors(),
          winopts = { backdrop = backdrop_for(require('foxglove').palette() or {}) },
        }, true)
      end,
    })
  end,
}
