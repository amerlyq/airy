---@type vim.lsp.Config
return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  -- root_markers = { 'pyproject.toml', 'setup.py', 'ruff.toml', '.ruff.toml', '.git' },
  -- init_options = {
    settings = {
      -- ALT: args = { 'check', '--cache-dir', vim.fn.expand('~/.cache/ruff_cache'), '--force-exclude', '--quiet', '--stdin-filename', function() return vim.api.nvim_buf_get_name(0) end }
      -- cacheDir = pjroot .. ".ruff_cache",
      -- cacheDir = vim.fn.expand('~/.cache/ruff'),
      -- lineLength = 88,
      organizeImports = true,
      fixAll = true,
      lint = {
        enabled = true,
        select = { "E", "F", "I", "PL" }, -- Includes Pylint rules
        live_mode = true, -- Shows errors as you type, before you even save
        extendSelect = { "I" }, -- "I" includes isort-like import sorting
        format = { "I" },       -- Ensures sorting is part of formatting
      },
    },
  -- }
  -- Optional: Configure on_attach to prevent Ruff from overriding formatting if you use another formatter
  on_attach = function(client, bufnr)
    -- Disable Ruff's hover capabilities if you are using Pyright/Ruff together
    client.server_capabilities.hoverProvider = false
  end,

  -- Explicitly declare capabilities to stop the warning
  capabilities = {
    workspace = {
      didChangeConfiguration = {
        dynamicRegistration = false,
      },
    },
  },
}
