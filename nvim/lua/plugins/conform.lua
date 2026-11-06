return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>ta',
      function()
        vim.g.autoformat = not vim.g.autoformat
        print('autoformat ' .. (vim.g.autoformat and 'on' or 'off'))
      end,
      mode = { 'n', 'v' },
      desc = 'toggle autoformat',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      if not vim.g.autoformat then
        return nil
      end

      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      end
      return { lsp_format = 'first', timeout_ms = 500 }
    end,
    formatters_by_ft = {
      lua = { 'stylua' }
    },
  },
}
