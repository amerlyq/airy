print(123)

vim.cmd [[packadd nvim-lspconfig]]

local on_attach = function(client, bufnr)
  vim.api.nvim_create_autocmd('BufWritePre', {
    buffer = 0,
    callback = vim.lsp.buf.formatting_sync
  })
end

local settings = {
  pylsp = {
    -- configurationSources = {"pylint"},
    plugins = {
      pylint = { enabled = true },
      isort = { enabled = true },
      black = { enabled = true, cache_config = true },
      mypy = { enabled = true },
      -- rope_completion = { enabled = true },
    }
  },
}

local lspconfig = require 'lspconfig'
local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- ALSO: { 'sumneko_lua', 'clangd', 'rust_analyzer', 'pyright', 'tsserver' }
local servers = { 'pylsp' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = settings,
  }
end
