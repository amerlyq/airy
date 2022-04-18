-- DEPS: aur/python-lsp-all
--   NEED python-lsp-server, python-lsp-black, python-lsp-isort, python-lsp-mypy, python-pylsp-rope, python-pylint
--   OPT: python-pyflakes, python-mccabe, python-pycodestyle, python-pydocstyle,python-rope, flake8
--   ALSO: pip install pylsp-autoimport && auri python-autoimport

-- SRC: https://github.com/neovim/nvim-lspconfig
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
-- vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
vim.api.nvim_set_keymap('n', '<LocalLeader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

-- local capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  -- OR: :autocmd Filetype python setlocal omnifunc=v:lua.vim.lsp.omnifunc
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Format on save -- and restore highlights
  vim.cmd [[autocmd BufWritePre <buffer> exe 'lua vim.lsp.buf.formatting_sync()'|Semshi highlight]]

  -- FIXED: too bright hi! for !neovim LSP ※⡢⡔⢀⠔
  -- vim.cmd [[hi! DiagnosticUnderlineWarn term=underline gui=underline guisp=#5f5f00]]
  vim.cmd [[hi! DiagnosticWarn ctermfg=94 guifg=#875f00]]



  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>g', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>d', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>R', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>u', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<LocalLeader>F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  -- nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
  -- nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- local servers = { 'pyright', 'rust_analyzer', 'tsserver' }
-- for _, lsp in pairs(servers) do
--   require('lspconfig')[lsp].setup {
--     on_attach = on_attach, flags = { debounce_text_changes = 150, } }
-- end

-- VIZ: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
require("lspconfig").pylsp.setup {
  on_attach = on_attach,
  -- This will be the default in neovim 0.7+
  flags = { debounce_text_changes = 150 },
  filetypes = {"python"},
  -- capabilities = capabilities,
  settings = {
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
        -- isort = { enabled = true },
        -- black = { enabled = true, cache_config = true },
        mypy = { enabled = true },
        rope_completion = { enabled = true },

        -- DEP: pylsp-autoimport
        -- FAIL: autoimport = { enabled = true },
        -- SRC: https://github.com/bageljrkhanofemus/dotfiles/blob/4a8d7e555ca96d0d4b17eda6ed37c68c7ec6a045/dot_config/nvim/lua/configs/lsp.lua
        rope_autoimport = { enabled = true },

        pydocstyle = { enabled = false },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        flake8 = { enabled = false },
        pycodestyle = { enabled = false, maxLineLength = 88 },
        pyflakes = { enabled = false },
      }
    }
  }
}

-- require("refactoring").setup({})
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = false,
})

