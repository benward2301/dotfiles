return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  event = 'VeryLazy',
  config = function()

    local pwin, ppath
    local neo_tree_sources = { 'filesystem', 'buffers', 'git_status', 'document_symbols' }

    local function get_neotree_source()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buffer_name = vim.api.nvim_buf_get_name(buf)
        for _, source in ipairs(neo_tree_sources) do
          if buffer_name:match('neo%-tree.*' .. source) then
            return source
          end
        end
      end

      return 'filesystem'
    end

    local function get_all_visible_nodes()
      local manager = require 'neo-tree.sources.manager'
      local source = get_neotree_source()
      local state = manager.get_state(source)
      if not state or not state.tree then
        return {}
      end

      local renderer = require 'neo-tree.ui.renderer'
      return renderer.get_all_visible_nodes(state.tree)
    end

    local neo_tree_mappings = {
      ['l'] = 'open_with_window_picker',
      ['f'] = {
        function()
          if ppath then
            require('neo-tree.command').execute {
              action = 'show',
              source = 'filesystem',
              reveal_file = ppath,
              reveal_force_cwd = true,
            }
          end
        end,
        desc = 'select open file',
      },
      ['F'] = {
        function(state)
          local node = state.tree:get_node()
          local scope_dir = node.type == 'directory' and node:get_id() or vim.fn.fnamemodify(node:get_id(), ':h')
          require('fzf-lua').files { cwd = scope_dir }
        end,
        desc = 'search files in directory',
      },
      ['O'] = {
        function(state)
          vim.cmd('Oil --float ' .. state.tree:get_node().path)
        end,
        desc = 'edit with oil',
      },
      ['H'] = {
        function(state)
          local parent_id = state.tree:get_node():get_parent_id()
          if not parent_id then
            return
          end
          if state.name ~= 'filesystem' then
            require('neo-tree.ui.renderer').focus_node(state, parent_id)
          else
            require('neo-tree.command').execute {
              action = 'show',
              reveal_file = parent_id,
              reveal_force_cwd = true,
            }
          end
        end,
        desc = 'select parent',
      },
      ['L'] = {
        function(state)
          local tree = state.tree
          local function get_parent_next_sibling(current_node)
            local parent_id = current_node:get_parent_id()
            if not parent_id or (parent_id == vim.fn.getcwd()) then
              return current_node
            end
            local parent_node = tree:get_node(parent_id)
            local parent_siblings = tree:get_nodes(parent_node:get_parent_id())
            local parent_index = nil
            for i, node in ipairs(parent_siblings) do
              if node == parent_node then
                parent_index = i
                break
              end
            end
            local parent_next_sibling = parent_siblings[parent_index + 1]
            if parent_next_sibling then
              return parent_next_sibling
            end
            return get_parent_next_sibling(parent_node)
          end
          local renderer = require 'neo-tree.ui.renderer'
          renderer.focus_node(state, get_parent_next_sibling(tree:get_node()):get_id())
        end,
        desc = 'select next after parent',
      },
      ['K'] = {
        function(state)
          local current_node = state.tree:get_node()
          if not current_node then
            return
          end

          local visible_nodes = get_all_visible_nodes()
          local current_index = nil

          for i, node in ipairs(visible_nodes) do
            if node.id == current_node.id then
              current_index = i
              break
            end
          end

          if not current_index then
            return
          end

          for i = current_index - 1, 1, -1 do
            local node = visible_nodes[i]
            if node.type ~= current_node.type or node:get_depth() ~= current_node:get_depth() then
              require('neo-tree.ui.renderer').focus_node(state, node.id)
              return
            end
          end
        end,
        desc = 'move up to different level or type',
      },
      ['J'] = {
        function(state)
          local current_node = state.tree:get_node()
          if not current_node then
            return
          end

          local visible_nodes = get_all_visible_nodes()
          local current_index = nil

          for i, node in ipairs(visible_nodes) do
            if node.id == current_node.id then
              current_index = i
              break
            end
          end

          if not current_index then
            return
          end

          for i = current_index + 1, #visible_nodes do
            local node = visible_nodes[i]
            if node.type ~= current_node.type or node:get_depth() ~= current_node:get_depth() then
              require('neo-tree.ui.renderer').focus_node(state, node.id)
              return
            end
          end
        end,
        desc = 'move down to different level or type',
      },

      ['#'] = 'noop',
      ['/'] = 'noop',
      ['<space>'] = 'noop',
      ['<C-t>'] = {
        function(state)
          local node = state.tree:get_node()
          if node.type == 'directory' then
            return
          end
          vim.cmd('tabedit ' .. vim.fn.fnameescape(node:get_id()))
        end,
        desc = 'open file in tab',
      },
      ['P'] = { 'toggle_preview', config = { use_float = true } },
      ['M'] = 'close_all_nodes',
      [')'] = {
        function()
          vim.cmd 'vertical resize +20'
        end,
        desc = 'increase width',
      },
      ['('] = {
        function()
          vim.cmd 'vertical resize -20'
        end,
        desc = 'decrease width',
      },
      ['<A-a>'] = {
        function(state)
          local visible_nodes = get_all_visible_nodes()
          if #visible_nodes > 0 then
            require('neo-tree.ui.renderer').focus_node(state, visible_nodes[1].id)
          end
        end,
        desc = 'go to first node',
      },
      ['<A-e>'] = {
        function(state)
          local visible_nodes = get_all_visible_nodes()
          if #visible_nodes > 0 then
            require('neo-tree.ui.renderer').focus_node(state, visible_nodes[#visible_nodes].id)
          end
        end,
        desc = 'go to last node',
      },
    }

    local renderer = require 'neo-tree.ui.renderer'

    local function open_dir(state, dir_node)
      if state.name == 'filesystem' then
        local fs = require 'neo-tree.sources.filesystem'
        fs.toggle_directory(state, dir_node, nil, true, false)
      elseif not dir_node:is_expanded() then
        dir_node:expand()
      end
    end

    local function is_expandable(node)
      return node.type == 'directory' or (node.type ~= 'file' and node:has_children())
    end

    local function recursive_open(state, node, max_depth)
      local max_depth_reached = 1
      local stack = { node }
      while next(stack) ~= nil do
        node = table.remove(stack)
        if is_expandable(node) and not node:is_expanded() then
          open_dir(state, node)
        end

        local depth = node:get_depth()
        max_depth_reached = math.max(depth, max_depth_reached)

        if not max_depth or depth < max_depth - 1 then
          local children = state.tree:get_nodes(node:get_id())
          for _, v in ipairs(children) do
            table.insert(stack, v)
          end
        end
      end

      return max_depth_reached
    end

    local function neotree_zo(state, open_all)
      local node = state.tree:get_node()

      if open_all then
        recursive_open(state, node)
      else
        recursive_open(state, node, node:get_depth() + vim.v.count1)
      end

      renderer.redraw(state)
    end

    local function neotree_zO(state)
      neotree_zo(state, true)
    end

    local MIN_DEPTH = 2

    local function recursive_close(state, node, max_depth)
      if max_depth == nil or max_depth <= MIN_DEPTH then
        max_depth = MIN_DEPTH
      end

      local last = node
      while node and node:get_depth() >= max_depth do
        if node:has_children() and node:is_expanded() then
          node:collapse()
        end
        last = node
        node = state.tree:get_node(node:get_parent_id())
      end

      return last
    end

    local function neotree_zc(state, close_all)
      local node = state.tree:get_node()
      if not node then
        return
      end

      local max_depth
      if not close_all then
        max_depth = node:get_depth() - vim.v.count1
        if node:has_children() and node:is_expanded() then
          max_depth = max_depth + 1
        end
      end

      local last = recursive_close(state, node, max_depth)
      renderer.redraw(state)
      renderer.focus_node(state, last:get_id())
    end

    local function neotree_zC(state)
      neotree_zc(state, true)
    end

    local function neotree_za(state, toggle_all)
      local node = state.tree:get_node()
      if not node then
        return
      end

      if is_expandable(node) and not node:is_expanded() then
        neotree_zo(state, toggle_all)
      else
        neotree_zc(state, toggle_all)
      end
    end

    local function neotree_zA(state)
      neotree_za(state, true)
    end

    local function set_depthlevel(state, depthlevel)
      if depthlevel < MIN_DEPTH then
        depthlevel = MIN_DEPTH
      end

      local stack = state.tree:get_nodes()
      while next(stack) ~= nil do
        local node = table.remove(stack)

        if is_expandable(node) then
          local should_be_open = depthlevel == nil or node:get_depth() < depthlevel
          if should_be_open and not node:is_expanded() then
            open_dir(state, node)
          elseif not should_be_open and node:is_expanded() then
            node:collapse()
          end
        end

        local children = state.tree:get_nodes(node:get_id())
        for _, v in ipairs(children) do
          table.insert(stack, v)
        end
      end

      vim.b.neotree_depthlevel = depthlevel
    end

    local function redraw_after_depthlevel_change(state, stay)
      local node = state.tree:get_node()

      if stay then
        renderer.expand_to_node(state.tree, node)
      else
        local parent = state.tree:get_node(node:get_parent_id())
        while parent and not parent:is_expanded() and parent:get_depth() > 1 do
          node = parent
          parent = state.tree:get_node(node:get_parent_id())
        end
      end

      renderer.redraw(state)
      renderer.focus_node(state, node:get_id())
    end

    local function neotree_zx(state)
      set_depthlevel(state, vim.b.neotree_depthlevel or MIN_DEPTH)
      redraw_after_depthlevel_change(state, true)
    end

    local function neotree_zX(state)
      set_depthlevel(state, vim.b.neotree_depthlevel or MIN_DEPTH)
      redraw_after_depthlevel_change(state, false)
    end

    local function neotree_zm(state)
      local depthlevel = vim.b.neotree_depthlevel or MIN_DEPTH
      set_depthlevel(state, depthlevel - vim.v.count1)
      redraw_after_depthlevel_change(state, false)
    end

    local function neotree_zM(state)
      set_depthlevel(state, MIN_DEPTH)
      redraw_after_depthlevel_change(state, false)
    end

    local function neotree_zr(state)
      local depthlevel = vim.b.neotree_depthlevel or MIN_DEPTH
      set_depthlevel(state, depthlevel + vim.v.count1)
      redraw_after_depthlevel_change(state, false)
    end

    local function neotree_zR(state)
      local top_level_nodes = state.tree:get_nodes()

      local max_depth = 1
      for _, node in ipairs(top_level_nodes) do
        max_depth = math.max(max_depth, recursive_open(state, node))
      end

      vim.b.neotree_depthlevel = max_depth
      redraw_after_depthlevel_change(state, false)
    end

    neo_tree_mappings['z'] = 'none'
    neo_tree_mappings['zo'] = neotree_zo
    neo_tree_mappings['zO'] = neotree_zO
    neo_tree_mappings['zc'] = neotree_zc
    neo_tree_mappings['zC'] = neotree_zC
    neo_tree_mappings['za'] = neotree_za
    neo_tree_mappings['zA'] = neotree_zA
    neo_tree_mappings['zx'] = neotree_zx
    neo_tree_mappings['zX'] = neotree_zX
    neo_tree_mappings['zm'] = neotree_zm
    neo_tree_mappings['zM'] = neotree_zM
    neo_tree_mappings['zr'] = neotree_zr
    neo_tree_mappings['zR'] = neotree_zR

    local neo_tree_fs_mappings = {
      ['<C-j>'] = 'next_git_modified',
      ['<C-k>'] = 'prev_git_modified',
      ['h'] = 'toggle_hidden',
    }

    for k, v in pairs(neo_tree_mappings) do
      neo_tree_fs_mappings[k] = v
    end

    require('neo-tree').setup {
      close_if_last_window = true,
      sources = neo_tree_sources,
      source_selector = {
        sources = {
          { source = 'filesystem' },
          { source = 'buffers' },
          { source = 'git_status' },
          { source = 'document_symbols' },
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        filtered_items = {
          hide_dotfiles = false,
          hide_by_name = { '.git' },
        },
        window = {
          mappings = neo_tree_fs_mappings,
        },
      },
      buffers = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        window = {
          mappings = neo_tree_mappings,
        },
      },
      git_status = {
        window = {
          mappings = neo_tree_mappings,
        },
      },
      document_symbols = {
        follow_cursor = true,
        renderers = {
          root = {
            { 'name' },
          },
          symbol = {
            { 'indent', with_expanders = true },
            { 'kind_icon', default = '?' },
            { 'container', content = {
              { 'name', zindex = 10 },
            } },
          },
        },
        window = {
          mappings = neo_tree_mappings,
        },
      },
      default_component_configs = {
        icon = {
          default = '',
          highlight = 'NeoTreeNormal',
        },
        diagnostics = {
          symbols = {
            error = '󰅚 ',
            warn = '󰀪 ',
            info = '󰋽 ',
            hint = ' ',
          },
        },
      },
    }

    vim.api.nvim_set_hl(0, 'NeoTreeCursor', { blend = 100 })

    local map = vim.keymap.set

    local open_neo_tree = function()
      if string.find(vim.fn.expand '%', 'neo-tree ', 1, true) == 1 then
        if pwin and vim.api.nvim_win_is_valid(pwin) then
          vim.api.nvim_set_current_win(pwin)
        else
          vim.cmd 'wincmd p'
        end
      else
        pwin = vim.api.nvim_get_current_win()
        ppath = vim.fn.expand(vim.fn.expand '%:p')
        require('neo-tree.command').execute {
          action = 'focus',
          source = 'last',
        }
      end
    end

    map({ 'n', 'v' }, '\\', open_neo_tree, { desc = 'neo-tree: open' })
    map({ 'n', 'v' }, '<leader>e', '<cmd>Neotree show source=last toggle<CR>', { desc = 'neo-tree: toggle' })

    vim.api.nvim_create_autocmd('FocusGained', {
      callback = function()
        require('neo-tree.events').fire_event 'git_event'
      end,
    })

  end,
}
