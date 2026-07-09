---@type vim.lsp.Config
return {
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", ".git" },
  settings = {
    pylsp = {
      plugins = {
        pyflakes = { enabled = false },
        mccabe = { enabled = false },
        pycodestyle = { enabled = false },
        yapf = { enabled = false },
        autopep8 = { enabled = false },
        flake8 = { enabled = false },

        pylsp_rope = { enabled = true }, -- Keep refactoring alive
      },
    },
  },
}
