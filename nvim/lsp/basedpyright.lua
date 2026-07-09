---@type vim.lsp.Config
return {
  -- cmd = { 'basedpyright-langserver', '--stdio' },
  -- filetypes = { 'python' },
  -- root_markers = { 'pyproject.toml', 'setup.py', '.git' },
  settings = {
    --# DEBUG: :lua print(vim.inspect(vim.lsp.get_clients({name = "basedpyright"})[1].config.settings))
    basedpyright = {
      -- REF: https://github.com/astral-sh/ruff/blob/main/docs/editors/setup.md
      disableOrganizeImports = true, -- <(LSP/editor-only): Using Ruff's import organizer

      analysis = {
        -- IMPORTANT: Disable diagnostics so it doesn't fight Mypy/Ruff
        -- typeCheckingMode = "off",
        typeCheckingMode = "strict", -- or "off" if you only want navigation

        autoImportCompletions = true, -- Enable auto-import suggestions
        importFormat = "relative",  -- <(LSP/editor-only); DFL=absolute

        autoSearchPaths = true,
        useLibraryCodeForTypes = true,

        -- Disable things Ruff handles better:
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          reportUnusedVariable = "none",
          reportDuplicateImport = "none",
        },
      }
    }
  }
}
