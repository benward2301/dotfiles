return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()

    require('foxglove').highlight('AlphaDirPart', function(palette)
      return { fg = palette.subtext1 }
    end)

    local theta = require 'alpha.themes.theta'
    local dashboard = require 'alpha.themes.dashboard'
    local utils = require 'alpha.utils'

    theta.file_icons.provider = 'devicons'
    theta.header.val = {
      [[                            ]],
      [[▗▖ ▗▖▗▄▄▖ ▗▄▖ ▗▖  ▗▖▗▖▗▖  ▗▖]],
      [[▐▛▚▟▌▐▙▄ ▐▌ ▐▌▐▌  ▐▌▐▌▐▛▚▞▜▌]],
      [[▐▌ ▐▌▐▙▄▖▝▚▄▞▘ ▝▚▞▘ ▐▌▐▌  ▐▌]],
      [[                            ]],
    }
    theta.header.opts = { hl = 'AlphaHeader', position = 'center' }
    theta.buttons.val = {
      { type = 'text', val = 'Quick links', opts = { hl = 'SpecialComment', position = 'center' } },
      { type = 'padding', val = 1 },
      dashboard.button('i', '  New buffer', '<cmd>enew | startinsert<CR>'),
      dashboard.button(
        'r',
        '  Restore session',
        '<cmd>lua if vim.fn.getcwd() == os.getenv("HOME") then vim.cmd("SessionSearch") else vim.cmd("SessionRestore") end<CR>'
      ),
      dashboard.button('f', '󰱼  Find files', '<cmd>lua require("fzf-lua").files()<CR>'),
      dashboard.button('s', '󱎸  Live grep', '<cmd>lua require("fzf-lua").live_grep()<CR>'),
      dashboard.button('d', '  Diff view', '<cmd>lua vim.g.diffview_replace_tab = true<CR><cmd>DiffviewOpen<CR>'),
      dashboard.button('q', '󰅚  Quit', '<cmd>q<CR>'),
    }

    local function shorten_path(fn)
      local parts = vim.split(fn, '/', { plain = true })
      for i = 1, #parts - 2 do
        local p = parts[i]
        if p ~= '' then
          local keep = (p:sub(1, 1) == '.') and 2 or 1
          if #p > keep then parts[i] = p:sub(1, keep) end
        end
      end
      return table.concat(parts, '/')
    end

    local wt_cache = { cwd = nil }
    local function worktree_info()
      local cwd = vim.fn.getcwd()
      if wt_cache.cwd == cwd then
        return wt_cache.root, wt_cache.others
      end
      wt_cache.cwd = cwd
      wt_cache.root = nil
      wt_cache.others = {}
      local top = vim.fn.systemlist { 'git', '-C', cwd, 'rev-parse', '--show-toplevel' }
      if vim.v.shell_error ~= 0 or not top[1] or top[1] == '' then
        return nil, {}
      end
      wt_cache.root = top[1]
      local list = vim.fn.systemlist { 'git', '-C', cwd, 'worktree', 'list', '--porcelain' }
      if vim.v.shell_error == 0 then
        for _, line in ipairs(list) do
          local w = line:match '^worktree (.+)$'
          if w and w ~= wt_cache.root then
            table.insert(wt_cache.others, w)
          end
        end
      end
      return wt_cache.root, wt_cache.others
    end

    local function ignore_fn(path, ext)
      if path:find 'COMMIT_EDITMSG' then return true end
      if ext == 'gitcommit' then return true end
      local root, others = worktree_info()
      if not root then return false end
      local best_root, best_len = nil, 0
      local function check(r)
        local prefix = r .. '/'
        if vim.startswith(path, prefix) and #prefix > best_len then
          best_root = r
          best_len = #prefix
        end
      end
      check(root)
      for _, o in ipairs(others) do check(o) end
      return best_root ~= root
    end

    local function file_button(fn, sc, short_fn)
      local ico, hl = utils.get_icon(theta.file_icons, fn)
      local ico_txt = ico .. '  '
      local fb_hl = {}
      if hl then table.insert(fb_hl, { hl, 0, #ico }) end
      local btn = dashboard.button(sc, ico_txt .. short_fn, '<cmd>e ' .. vim.fn.fnameescape(fn) .. ' <CR>')
      local fn_start = short_fn:match '.*[/\\]'
      if fn_start then
        table.insert(fb_hl, { 'AlphaDirPart', #ico_txt - 2, #fn_start + #ico_txt })
      end
      btn.opts.cursor = vim.fn.strdisplaywidth(ico_txt)
      btn.opts.hl = fb_hl
      return btn
    end

    local function mru_group(cwd, items_number)
      items_number = items_number or 10
      local found = utils.get_mru(cwd, items_number, ignore_fn)
      local tbl = {}
      for i, fn in ipairs(found) do
        local short_fn = cwd and vim.fn.fnamemodify(fn, ':.') or vim.fn.fnamemodify(fn, ':~')
        if #short_fn > 35 then
          short_fn = shorten_path(short_fn)
        end
        tbl[i] = file_button(fn, tostring(i - 1), short_fn)
      end
      return { type = 'group', val = tbl, opts = {} }
    end

    local mru_el = theta.config.layout[4].val[3]
    mru_el.val = function()
      local group = mru_group(vim.fn.getcwd())
      for _, button in ipairs(group.val) do
        if #button.val > 50 then
          button.val = string.sub(button.val, 0, 49) .. '..'
        end
      end
      return { group }
    end

    require('alpha').setup(theta.config)

  end,
}
