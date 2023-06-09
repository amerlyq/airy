-- LSP settings
-- Collection of configurations for built-in LSP client
-- SRC: https://github.com/neovim/nvim-lspconfig

--NOTE:(sfx=!): only add to &rtp for init.vim access, don't source plugin/*
vim.cmd [[ packadd! nvim-lspconfig ]]


local lspconfig = require 'lspconfig'
local capabilities = vim.lsp.protocol.make_client_capabilities()
-- nvim-cmp supports additional completion capabilities
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- Enable the following language servers
-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- ALSO: { 'clangd', 'rust_analyzer', 'pyright', 'tsserver' }
-- TODO  'sumneko_lua' -> 'lua_ls' for 'lspconfig>=0.2.0'
local servers = { 'pylsp' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = require('lsp.attach'),
    capabilities = capabilities,
    settings = require('lsp.' .. lsp),
    -- filetypes = {"python"},
    -- flags = { debounce_text_changes = 150 }, -- NOTE:DFL for !neovim>=0.7
  }
end


-- FAIL: I don't want to trigger all events in ALL groups for ft=python again
-- vim.api.nvim_exec_autocmds({'FileType'}, {group='', buffer=0, pattern='python', modeline=false})
--HACK: copy-pasted "autocmd FileType" to avoid triggering all events for python in ALL plugins
--  NOTE: run only once -- for the current buffer, which triggered "packadd", afterwards STD autocmd will do same
if vim.bo.filetype == 'python' then
  require 'lspconfig'["pylsp"].manager.try_add()
-- elseif vim.bo.filetype == 'lua' then
--   require 'lspconfig'["sumneko_lua"].manager.try_add()
end

if vim.bo.filetype == 'c' or vim.bo.filetype == 'cpp' then
  vim.cmd [[ packadd clangd_extensions.nvim ]]
  -- FIXME: probably should be merged
  require("clangd_extensions").setup {
    server = {
      on_attach = require('lsp.attach'),
      capabilities = capabilities,
      settings = require('lsp.' .. 'clangd'),
    }
  }
  require 'lspconfig'["clangd"].manager.try_add()
end


-- NOTE:(vim_starting=1): if launched by opening .py file
--   >> defer till startup next step "plugin/*" auto sourcing
if vim.fn.has('vim_starting') == 0 then
  --WARN:(packadd again): usually plugin/* should be sourced AFTER vimrc, not before
  --  NICE: no duplicate &rtp entries added
  vim.cmd [[packadd nvim-lspconfig]]
end
