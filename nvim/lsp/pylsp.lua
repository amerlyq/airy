---@type vim.lsp.Config
return {
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", ".git" },
  settings = {
    pylsp = {
      plugins = {

        pylint = { enabled = false },
        pylsp_mypy = { enabled = false },
        jedi = { enabled = false },
        jedi_definition = { enabled = false },
        jedi_completion = { enabled = false },
        jedi_rename = {enabled = false},
        jedi_hover = { enabled = false },
        jedi_references = { enabled = false },
        jedi_symbols = { enabled = false },

        pylsp_rope = { enabled = true }, -- Keep refactoring alive
        rope_autoimport = { enabled = false },
        rope_rename = { enabled = false },
        isort = { enabled = false },
        black = { enabled = false },
        ruff = { enabled = false },

        pydocstyle = { enabled = false },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        flake8 = { enabled = false },
        pycodestyle = { enabled = false },
        pyflakes = { enabled = false },
        autoflake = { enabled = false },
        mccabe = { enabled = false },
      },
    },
  },
}
