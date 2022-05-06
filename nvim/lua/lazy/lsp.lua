
--NOTE:(sfx=!): only add to &rtp for init.vim access, don't source plugin/*
vim.cmd [[ packadd! nvim-lspconfig ]]


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
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- ALSO: { 'sumneko_lua', 'clangd', 'rust_analyzer', 'pyright', 'tsserver' }
local servers = { 'pylsp' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = settings,
  }
end


-- FAIL: I don't want to trigger all events in ALL groups for ft=python again
-- vim.api.nvim_exec_autocmds({'FileType'}, {group='', buffer=0, pattern='python', modeline=false})
--HACK: copy-pasted "autocmd FileType" to avoid triggering all events for python in ALL plugins
--  NOTE: run only once -- for the current buffer, which triggered "packadd", afterwards STD autocmd will do same
require'lspconfig'["pylsp"].manager.try_add()


-- NOTE:(vim_starting=1): if launched by opening .py file
--   >> defer till startup next step "plugin/*" auto sourcing
if vim.fn.has('vim_starting') == 0 then
  --WARN:(packadd again): usually plugin/* should be sourced AFTER vimrc, not before
  --  NICE: no duplicate &rtp entries added
vim.cmd [[packadd nvim-lspconfig]]
end
