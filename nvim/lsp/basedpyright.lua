---@type vim.lsp.Config
return {
  -- cmd = { 'basedpyright-langserver', '--stdio' },
  -- filetypes = { 'python' },
  -- root_markers = { 'pyproject.toml', 'setup.py', '.git' },
  settings = {
    basedpyright = {
      -- REF: https://github.com/astral-sh/ruff/blob/main/docs/editors/setup.md
      disableOrganizeImports = true, -- <Using Ruff's import organizer
      analysis = {
        -- IMPORTANT: Disable diagnostics so it doesn't fight Mypy/Ruff
        -- typeCheckingMode = "off",
        typeCheckingMode = "strict", -- or "off" if you only want navigation
        autoImportCompletions = true,
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
