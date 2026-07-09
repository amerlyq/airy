---@type vim.lsp.Config
return {
  cmd = { "basilisk" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", ".git" },
}
