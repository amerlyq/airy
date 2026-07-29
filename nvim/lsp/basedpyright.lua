---@type vim.lsp.Config
return {
  -- cmd = { 'basedpyright-langserver', '--stdio' },
  -- filetypes = { 'python' },
  -- root_markers = { 'pyproject.toml', 'setup.py', '.git' },

  -- FAIL:
  -- CRITICAL: This dictates the initialization handshake state
  -- init_options = {
  --   settings = {
  --     basedpyright = {
  --       analysis = {
  --         importFormat = "relative",
  --       },
  --     },
  --   },
  -- },

  -- FAIL:
  -- Force the root_dir analyzer to lock onto the package folder rather than the broad uv workspace root
  -- root_dir = function(fname)
  --   return vim.fs.root(fname, { "src" }) or vim.fs.root(fname, { "pyproject.toml", ".git" })
  -- end,

  -- If you're using a completion plugin (blink.cmp, nvim-cmp/cmp-nvim-lsp)
  -- that already builds a capabilities table, merge into that instead of overwriting it — e.g.
  --   vim.tbl_deep_extend("force", require("blink.cmp").get_lsp_capabilities(), { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }).
  -- CHECK: should fix "symbol not found" when importing from newly created modules without nvim restart
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },

  -- Fallback block for runtime configuration modifications
  settings = {
    --# DEBUG: :lua print(vim.inspect(vim.lsp.get_clients({name = "basedpyright"})[1].config.settings))
    basedpyright = {
      -- REF: https://github.com/astral-sh/ruff/blob/main/docs/editors/setup.md
      disableOrganizeImports = true, -- <(LSP/editor-only): Using Ruff's import organizer

      analysis = {
        -- IMPORTANT: Disable diagnostics so it doesn't fight Mypy/Ruff
        -- typeCheckingMode = "off",
        typeCheckingMode = "strict", -- or "off" if you only want navigation
        -- useLibraryCodeForTypes = true,

        autoImportCompletions = true, -- Enable auto-import suggestions
        -- FAIL: !uv installs your pkg into site-packages and thus prevents this from working
        --   FIXED? uv pip install -e . --config-setting editable_mode=compat
        --   SRC: https://github.com/astral-sh/uv/issues/11488
        --   REF: https://github.com/microsoft/pylance-release/blob/main/docs/settings/python_analysis_importFormat.md
        importFormat = "relative",  -- <(LSP/editor-only); DFL=absolute
        -- extraPaths = { "src" },  -- Force local file-tree tracing first

        -- CRITICAL: Disable autoSearchPaths to stop Pyright from mapping
        -- your local code to the .venv editable path.
        autoSearchPaths = false,
        -- autoSearchPaths = true,

        useLibraryCodeForTypes = true,

        -- diagnosticMode = "openFilesOnly",
        --# Disable things Ruff handles better:
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          reportUnusedVariable = "none",
          reportDuplicateImport = "none",
        },

        -- inlayHints = {
        --   callArgumentNames = false, -- This completely disables 'src=' and 'dst='
        --   variableTypes = true,      -- This keeps type hints active
        -- },
      }
    }
  }
}
