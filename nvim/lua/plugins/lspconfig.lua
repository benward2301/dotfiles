return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', cmd = { 'Mason', 'MasonInstall', 'MasonUpdate', 'MasonUninstall', 'MasonLog' }, opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
  },
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('grn', vim.lsp.buf.rename, 'rename')
        map('gra', vim.lsp.buf.code_action, 'show code actions', { 'n', 'x' })

        local fzf_lsp = require 'fzf-lua'
        map('grr', fzf_lsp.lsp_references, 'search references')
        map('gri', fzf_lsp.lsp_implementations, 'search implementations')
        map('grd', fzf_lsp.lsp_definitions, 'search definitions')
        map('gd', fzf_lsp.lsp_definitions, 'search definitions')
        map('grD', vim.lsp.buf.declaration, 'goto declarations')
        map('grt', fzf_lsp.lsp_typedefs, 'search type definitions')
        map('gro', fzf_lsp.lsp_document_symbols, 'search document symbols')
        map('grw', fzf_lsp.lsp_live_workspace_symbols, 'search workspace symbols')

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            print('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled { bufnr = event.buf } and 'on' or 'off'))
          end, 'toggle inlay hints')
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = ' ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
        format = function(diagnostic)
          return diagnostic.message
        end,
      },
    }

    vim.lsp.config('*', {
      capabilities = require('blink.cmp').get_lsp_capabilities(),
    })

    vim.lsp.config('lua_ls', {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
        },
      },
    })

    local servers = { 'bashls', 'yamlls', 'jsonls' }
    local tools = { 'jdtls', 'lua-language-server', 'marksman', 'lemminx', 'stylua' }

    require('mason-tool-installer').setup {
      ensure_installed = vim.list_extend(vim.list_extend({}, servers), tools),
    }

    require('mason-lspconfig').setup {
      ensure_installed = {},

      automatic_enable = { exclude = { 'stylua', 'jdtls' } },
    }
    vim.lsp.enable { 'lua_ls', 'marksman', 'lemminx' }
  end,
}
