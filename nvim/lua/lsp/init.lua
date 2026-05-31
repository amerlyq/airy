-- LSP settings
-- Collection of configurations for built-in LSP client
-- SRC: https://github.com/neovim/nvim-lspconfig

-- TODO: with Nvim 0.12 (nightly), you can use the builtin vim.pack plugin manager:
-- vim.pack.add{
--   { src = 'https://github.com/neovim/nvim-lspconfig' },
-- }

-- DEBUG :lua vim.cmd.edit(vim.lsp.get_log_path())
-- vim.lsp.set_log_level("debug")
-- vim.lsp.set_log_level("TRACE")
-- DEBUG: :LspInfo

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- FIXME? Two more 0.12 additions worth knowing:
--   * vim.o.autocomplete = true for native insert-mode completion (nvim-cmp optional now),
--   and vim.net.request() for HTTP calls from Lua without curl wrappers.

vim.lsp.config('*', {
  on_attach = require('lsp.attach'),
  capabilities = capabilities,
  -- root_markers = { '.git' },
  -- --NOTE: dynamic enable/disable by reusing "root_dir"
  -- root_dir = function(bufnr, on_dir)
  --   if not vim.fn.bufname(bufnr):match('%.txt$') then
  --     on_dir(vim.fn.getcwd())
  --   end
  -- end
})

if vim.bo.filetype == 'c' or vim.bo.filetype == 'cpp' then
  vim.cmd [[ packadd clangd_extensions.nvim ]]

  vim.lsp.config('clangd', {
    -- Add both to be safe, but clang-21 is the priority
    -- cmd = { "clangd", "--background-index", "--clang-tidy", "--query-driver=/usr/bin/clang-21,/usr/bin/gcc", },
    -- DFL: //nvim-lspconfig/lsp/clangd.lua
    -- filetypes = { 'c', 'cpp' },
    -- root_markers = { 'pyproject.toml', 'setup.py', '.git' },
    on_attach = require('lsp.attach'),
    capabilities = capabilities,
    -- settings = require('lsp.' .. 'clangd'),
  })
  -- FIXME: probably should be merged
  -- require("clangd_extensions").setup {
  --   server = {
  --     on_attach = require('lsp.attach'),
  --     capabilities = capabilities,
  --     settings = require('lsp.' .. 'clangd'),
  --   }
  -- }
  -- require 'lspconfig'["clangd"].launch()
  vim.lsp.enable('clangd')
end

-- FIXME! The `require('lspconfig')` "framework" is deprecated, use vim.lsp.config (see :help lspconfig-nvim-0.11) instead.
--    Feature will be removed in nvim-lspconfig v3.0.0
-- USE: vim.lsp.config('pylsp', { settings = require('lsp.' .. lsp), })
--      vim.lsp.enable('pylsp') -- OR enable({'luals', 'pyright'}) OR enable('clangd', false)
-- ex~:REF: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/pylsp.lua
-- ex~: ~/.config/nvim/lsp/lua_ls.lua
--    return {
--      cmd = { 'lua-language-server' },
--      filetypes = { 'lua' },
--      root_markers = { '.luarc.json', '.luacheckrc', '.git' },
--    }
-- DEBUG: open .py -> :checkhealth vim.lsp


----------------------------------------------------------------------
if false then
--NOTE:(sfx=!): only add to &rtp for init.vim access, don't source plugin/*
vim.cmd [[ packadd! nvim-lspconfig ]]


local lspconfig = require 'lspconfig'
local capabilities = vim.lsp.protocol.make_client_capabilities()
-- nvim-cmp supports additional completion capabilities
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- Enable the following language servers
-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- ALSO: { 'rust_analyzer', 'pyright', 'tsserver' }
-- TODO  'sumneko_lua' -> 'lua_ls' for 'lspconfig>=0.2.0'
local servers = { 'pylsp', 'clangd' }
-- local qnx_base = "/opt/qnx/qnx710"
-- local qnx_host = qnx_base .. "/host/linux/x86_64"
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    -- cmd = { "clangd-12", "--query-driver="..qnx_host.."/usr/bin/ntoaarch64-gcc" },
    -- PATH=qnx_host.."/usr/bin:"..vim.env.PATH,
    -- cmd_env = {QNX_HOST=qnx_host, QNX_TARGET=qnx_base .. "/target/qnx7"},
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
  require 'lspconfig'["pylsp"].launch()  -- ALT: :LspStart
-- elseif vim.bo.filetype == 'lua' then
--   require 'lspconfig'["sumneko_lua"].manager.try_add()
end



-- NOTE:(vim_starting=1): if launched by opening .py file
--   >> defer till startup next step "plugin/*" auto sourcing
if vim.fn.has('vim_starting') == 0 then
  --WARN:(packadd again): usually plugin/* should be sourced AFTER vimrc, not before
  --  NICE: no duplicate &rtp entries added
  vim.cmd [[packadd nvim-lspconfig]]
end

end
