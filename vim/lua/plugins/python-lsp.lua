-- DEPS: aur/python-lsp-all
--   NEED python-lsp-server, python-lsp-black, python-lsp-isort, python-lsp-mypy, python-pylsp-rope, python-pylint
--   OPT: python-pyflakes, python-mccabe, python-pycodestyle, python-pydocstyle,python-rope, flake8
--   ALSO: pip install pylsp-autoimport && auri python-autoimport

-- Diagnostic keymaps
-- REF: `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- SRC: https://github.com/neovim/nvim-lspconfig
-- local opts = { noremap=true, silent=true }
-- -- vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
-- vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
-- vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
-- vim.api.nvim_set_keymap('n', '<LocalLeader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = false,
})


-- LSP settings
-- Collection of configurations for built-in LSP client
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local lsp_mappings = function(_client, bufnr)
  -- Mappings.
  -- ALT: vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', '<LocalLeader>K', vim.lsp.buf.hover, opts)  -- DFL=K
  vim.keymap.set('n', '<LocalLeader>g', vim.lsp.buf.implementation, opts)  -- DFL=gi
  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  -- vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  -- vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  -- vim.keymap.set('n', '<leader>wl', function()
  --   vim.inspect(vim.lsp.buf.list_workspace_folders())
  -- end, opts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts) -- @me: <LocalLeader>d
  vim.keymap.set('n', '<LocalLeader>R', vim.lsp.buf.rename, opts) -- DFL=<leader>rn
  vim.keymap.set('n', '<LocalLeader>u', vim.lsp.buf.references, opts) -- DFL=gr
  -- vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<Tab>s', require('telescope.builtin').lsp_document_symbols, opts)

  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  vim.api.nvim_create_user_command("Format", vim.lsp.buf.formatting, {})

  -- nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
  -- nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
end


local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  -- OR: :autocmd Filetype python setlocal omnifunc=v:lua.vim.lsp.omnifunc
  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Format on save -- and restore highlights
  -- vim.cmd [[autocmd BufWritePre <buffer> exe 'lua vim.lsp.buf.formatting_sync()'|Semshi highlight]]
  vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]

  -- FIXED: too bright hi! for !neovim LSP ※⡢⡔⢀⠔
  -- vim.cmd [[hi! DiagnosticUnderlineWarn term=underline gui=underline guisp=#5f5f00]]
  vim.cmd [[hi! DiagnosticWarn ctermfg=94 guifg=#875f00]]

  lsp_mappings(bufnr)
end


-- VIZ: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
local settings = {
  -- NEED: nested "pylsp" dict
  --   TALK: https://github.com/neovim/nvim-lspconfig/issues/1347
  --   FIXED: https://neovim.discourse.group/t/pylsp-config-is-not-taken-into-account/1846/2
  pylsp = {
    -- ALT:DFL=pycodestyle
    --   FAIL: can't suppress file-wide errors like E266 "##" comments in !qute
    --   SRC:TALK: https://github.com/PyCQA/pycodestyle/issues/381
    -- DEPs: flake8 python-flake8-black python-flake8-docstrings python-flake8-isort python-flake8-typing-imports python-pytest-flake8
    configurationSources = {"pylint"},
    -- configurationSources = {"flake8"},
    -- SRC:WTF: https://github.com/neovim/nvim-lspconfig/issues/903
    -- formatCommand = {"black"}

    -- plugins = {
    --   autoimport = {enabled = true},
    --   rope_autoimport = { enabled = true },

    --   pycodestyle = { enabled = false, maxLineLength = 88 },
    --   pydocstyle = { enabled = false },
    --   isort = { enabled = false },
    --   black = { enabled = false },
    --   mypy = { enabled = false },
    --   rope = { enabled = false },
    --   flake8 = { enabled = false },
    --   pylint = { enabled = false },


    --   autopep8_format = {enabled = false},
    --   definition = {enabled = false},
    --   flake8_lint = {enabled = false},
    --   folding = {enabled = false},
    --   highlight = {enabled = false},
    --   hover = {enabled = false},
    --   jedi_completion = {enabled = false},
    --   jedi_rename = {enabled = false},
    --   mccabe_lint = {enabled = false},
    --   preload_imports = {enabled = false},
    --   pycodestyle_lint = {enabled = false},
    --   pydocstyle_lint = {enabled = false},
    --   pyflakes_lint = {enabled = false},
    --   pylint_lint = {enabled = false},
    --   references = {enabled = false},
    --   rope_completion = {enabled = false},
    --   rope_rename = {enabled = false},
    --   signature = {enabled = false},
    --   symbols = {enabled = false},
    --   yapf_format = {enabled = false},
    -- },
    plugins = {
      pylint = { enabled = true },
      -- pylint = { enabled = true, args = {"--disable C0301"}},
      -- pylint = { enabled = false, args = { "--rcfile=pylint.ini" }, },
      isort = { enabled = true },
      black = { enabled = true, cache_config = true },
      mypy = { enabled = true },
      rope_completion = { enabled = true },

      -- DEP: pylsp-autoimport
      -- FAIL: autoimport = { enabled = true },
      -- SRC: https://github.com/bageljrkhanofemus/dotfiles/blob/4a8d7e555ca96d0d4b17eda6ed37c68c7ec6a045/dot_config/nvim/lua/configs/lsp.lua
      -- WAIT https://github.com/python-lsp/python-lsp-server/pull/199
      -- NEED: $ pip install . --user
      rope_autoimport = { enabled = true },

      pydocstyle = { enabled = false },
      autopep8 = { enabled = false },
      yapf = { enabled = false },
      flake8 = { enabled = false },
      pycodestyle = { enabled = false, maxLineLength = 88 },
      pyflakes = { enabled = false },
    }
  },

  --DEP: $ paci lua-language-server
  Lua = { -- sumneko_lua
    runtime = {
      -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
      version = 'LuaJIT',
      -- Setup your lua path
      path = runtime_path,
    },
    diagnostics = {
      -- Get the language server to recognize the `vim` global
      globals = { 'vim' },
    },
    workspace = {
      -- Make the server aware of Neovim runtime files
      library = vim.api.nvim_get_runtime_file('', true),
    },
    -- Do not send telemetry data containing a randomized but unique identifier
    telemetry = {
      enable = false,
    },
  },
}


-- SRC: https://github.com/neovim/nvim-lspconfig
local lspconfig = require 'lspconfig'
-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)


-- Enable the following language servers
-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- local servers = { 'clangd', 'rust_analyzer', 'pyright', 'tsserver' }
local servers = { 'pylsp', 'sumneko_lua' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = settings,
    -- filetypes = {"python"},
    -- flags = { debounce_text_changes = 150 }, -- NOTE:DFL for !neovim>=0.7
  }
end
