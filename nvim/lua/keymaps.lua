local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')

map('t', '<esc><esc>', '<C-\\><C-n>')

map('n', 'c', [["_c]], { noremap = true })
map('n', 'C', [["_C]], { noremap = true })
map('x', 'c', [["_c]], { noremap = true })
map('n', 'x', [["_x]], { noremap = true })
map('x', 'x', [["_x]], { noremap = true })

map('c', '<C-p>', '<up>')
map('c', '<C-n>', '<down>')
map('c', '<C-x>', '<C-f>')

map({ 'i', 'c' }, '<C-f>', '<right>')
map({ 'i', 'c' }, '<C-b>', '<left>')
map({ 'i', 'c' }, '<C-a>', '<home>')
map({ 'i', 'c' }, '<C-e>', '<end>')
map({ 'i', 'c' }, '<A-f>', '<C-right>')
map({ 'i', 'c' }, '<A-b>', '<C-left>')
map({ 'i', 'c' }, '<C-d>', '<del>')
map({ 'i', 'c' }, '<C-h>', '<bs>')

map({ 'n', 'v' }, '<leader>w', '<cmd>w<CR>', { desc = 'write buffer' })
map({ 'n', 'v' }, '<leader>W', '<cmd>wall<CR>', { desc = 'write all' })

map({ 'n', 'v' }, 'q', '<cmd>q<CR>', { desc = 'quit window' })
map({ 'n', 'v' }, 'Q', function()
  if #vim.api.nvim_list_tabpages() > 1 then vim.cmd('tabclose') else vim.cmd('qa') end
end, { desc = 'close tab' })
map({ 'n', 'v' }, '<C-A-q>', '<cmd>cquit!<CR>', { desc = 'quit all and non-zero exit' })
map({ 'n', 'v' }, '<C-q>', 'q', { desc = 'record macro' })
map({ 'n', 'i' }, '<C-s>', '<esc>:wq<CR>', { desc = 'write and quit' })

map({ 'n', 'v' }, '^', '0')
map({ 'n', 'v' }, 'd^', 'd0')
map({ 'n', 'v' }, 'y^', 'y0')
map({ 'n', 'v' }, 'c^', 'c0')
map({ 'n', 'v' }, '0', '^')
map({ 'n', 'v' }, 'd0', 'd^')
map({ 'n', 'v' }, 'y0', 'y^')
map({ 'n', 'v' }, 'c0', 'c^')

map('n', '<A-n>', ':tabnext<CR>')
map('n', '<A-N>', ':tabprevious<CR>')

map('n', '<leader>E', ':e!<CR>')

map('n', '<leader><C-r>', '9999<C-r>', { desc = 'redo all' })

map('n', '+', function()
  vim.cmd 'keepjumps norm! [z'
  vim.cmd 'keepjumps norm! mz]z'
  vim.cmd "keepjumps norm! V'z"
  vim.api.nvim_buf_del_mark(0, 'z')
end)
map('v', '+', function()
  vim.api.nvim_input '<esc>+'
end)

map({ 'n', 'v' }, '<C-t>', '<C-w>s<C-w>Tgg<C-o>', { desc = 'open new tab' })

map('n', '<leader>Y', 'gg0vG$y', { desc = 'yank all ' })
map('n', '<leader>C', 'gg0vG$"_c', { desc = 'change all ' })
map('n', '<leader>D', 'gg0vG$d', { desc = 'delete all ' })
map('n', '<leader>V', 'gg0vG$', { desc = 'select all ' })

map({ 'n', 'v' }, '<A-o>', 'o<space><backspace><esc>', { desc = 'insert newline below' })
map({ 'n', 'v' }, '<A-O>', 'O<space><backspace><esc>', { desc = 'insert newline above' })

map('n', '<C-/>', 'gcc', { remap = true })
map('v', '<C-/>', 'gc', { remap = true })

for i = 1, 9 do
  map({ 'n', 'v' }, '<leader>' .. i, i .. 'gt')
end

map('n', '<backspace>', '"_d', { desc = 'null delete' })
map('x', '<backspace>', '"_d', { desc = 'null delete' })
map('o', '<backspace>', '_', { desc = 'current line' })

map('n', '<S-backspace>', '"_D', { desc = 'null delete to end of line' })
map('x', '<S-backspace>', '"_D', { desc = 'null delete to end of line' })

local function escape_path(path)
  return vim.fn.fnameescape(path)
end

local function neotree_node_path()
  local state = require('neo-tree.sources.manager').get_state 'filesystem'
  local node = state.tree:get_node()
  return node and node.path or nil
end

local function yank_result(result)
  vim.notify('Copied: ' .. result)
  vim.fn.setreg('+', result)
end

local function current_path(mod)
  if vim.bo.filetype == 'neo-tree' then
    local path = neotree_node_path()
    return path and escape_path(vim.fn.fnamemodify(path, mod)) or nil
  end
  return escape_path(vim.fn.expand('%' .. mod))
end

local function yank_path(mod)
  return function()
    local result = current_path(mod)
    if result then
      yank_result(result)
    end
  end
end

local function yank_path_with_range(mod)
  return function()
    local mode = vim.fn.mode()
    local is_visual = mode == 'v' or mode == 'V' or mode == '\22'
    local start_row = is_visual and vim.fn.line 'v' or vim.fn.line '.'
    local end_row = vim.fn.line '.'
    local lo = math.min(start_row, end_row)
    local hi = math.max(start_row, end_row)
    if is_visual then
      vim.api.nvim_feedkeys(vim.keycode '<esc>', 'nx', false)
    end
    yank_result(escape_path(vim.fn.expand('%' .. mod)) .. ':' .. lo .. (lo ~= hi and ',' .. hi or ''))
  end
end

map('n', '<leader>yf', yank_path ':.', { desc = 'yank relative path' })
map({ 'n', 'v' }, '<leader>yr', yank_path_with_range ':.', { desc = 'yank relative path and row range' })

map('n', '<leader>yF', yank_path ':p', { desc = 'yank absolute path' })
map({ 'n', 'v' }, '<leader>yR', yank_path_with_range ':p', { desc = 'yank absolute path and row range' })

map('n', '<leader>tw', ':setlocal wrap!<CR>:setlocal wrap?<CR>', { desc = 'toggle wrap' })
map('n', '<leader>tn', ':set number relativenumber!<CR>', { desc = 'toggle relative line numbers' })
map('n', '<leader>ts', ':set swapfile!<CR>:set swapfile?<CR>', { desc = 'toggle swapfile' })

map('n', 'gwr', '"wyiw:%sno/<C-r>=escape(@w, "/")<CR>//gc<left><left><left>', { desc = 'replace word' })
map('n', 'gWr', '"wyiW:%sno/<C-r>=escape(@w, "/")<CR>//gc<left><left><left>', { desc = 'replace word' })
map('v', 'gwr', '"wy:%sno/<C-r>=escape(@w, "/")<CR>//gc<left><left><left>', { desc = 'replace word' })

map({ 'n', 'v' }, '<leader>i', vim.lsp.buf.code_action, { desc = 'show code actions' })

map({ 'n', 'v' }, '<C-n>', '<cmd>cnext<CR>')
map({ 'n', 'v' }, '<C-p>', '<cmd>cprevious<CR>')
map({ 'n', 'v' }, '<C-j>', function()
  vim.api.nvim_input ']c'
end)
map({ 'n', 'v' }, '<C-k>', function()
  vim.api.nvim_input '[c'
end)
map('n', '<A-b>', function()
  vim.api.nvim_input ']b'
end)
map('n', '<A-B>', function()
  vim.api.nvim_input '[b'
end)

map({ 'i', 't' }, '<A-h>', function()
  vim.cmd 'wincmd h'
  vim.api.nvim_input '<esc>'
end)
map({ 'i', 't' }, '<A-j>', function()
  vim.cmd 'wincmd j'
  vim.api.nvim_input '<esc>'
end)
map({ 'i', 't' }, '<A-k>', function()
  vim.cmd 'wincmd k'
  vim.api.nvim_input '<esc>'
end)
map({ 'i', 't' }, '<A-l>', function()
  vim.cmd 'wincmd l'
  vim.api.nvim_input '<esc>'
end)
