-- DEPS: aur/python-lsp-all
--   NEED python-lsp-server, python-lsp-black, python-lsp-isort, python-lsp-mypy, python-pylsp-rope, python-pylint
--   OPT: python-pyflakes, python-mccabe, python-pycodestyle, python-pydocstyle,python-rope, flake8
--   ALSO: pip install pylsp-autoimport && auri python-autoimport


-- VIZ: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
local settings = {
  -- NEED: nested "pylsp" dict
  --   TALK: https://github.com/neovim/nvim-lspconfig/issues/1347
  --   FIXED: https://neovim.discourse.group/t/pylsp-config-is-not-taken-into-account/1846/2
  pylsp = {
    configurationSources = { "pylint" },
    plugins = {
      -- BAD:NEED: $ paci nuspell
      pylint = { enabled = true }, -- , args = {"--rcfile=pylint.ini", "--disable C0301"}
      isort = { enabled = true },
      black = { enabled = true, cache_config = true },
      mypy = { enabled = true,
        -- overrides = { "--python-executable", "/d/miur/.venv/bin/python", true }
        -- overrides = { "--config-file", mypy_config, true }
        -- MAYBE? | This setting is required by pylsp-mypy for dynamic executable overrides.
        --   allow_dangerous_code_execution = true,
      },
      -- rope_completion = { enabled = true },

      -- DEP: pylsp-autoimport
      -- FAIL: autoimport = { enabled = true },
      -- SRC: https://github.com/bageljrkhanofemus/dotfiles/blob/4a8d7e555ca96d0d4b17eda6ed37c68c7ec6a045/dot_config/nvim/lua/configs/lsp.lua
      -- WAIT https://github.com/python-lsp/python-lsp-server/pull/199
      -- NEED: $ pip install . --user
      -- DISABLED:ERR: code errors
      -- rope_autoimport = { enabled = true },

      pydocstyle = { enabled = false },
      autopep8 = { enabled = false },
      yapf = { enabled = false },
      flake8 = { enabled = false },
      pycodestyle = { enabled = false, maxLineLength = 88 },
      pyflakes = { enabled = false },
    },
  }
}

return settings

-- ALT:DFL=pycodestyle
--   FAIL: can't suppress file-wide errors like E266 "##" comments in !qute
--   SRC:TALK: https://github.com/PyCQA/pycodestyle/issues/381
-- DEPs: flake8 python-flake8-black python-flake8-docstrings python-flake8-isort python-flake8-typing-imports python-pytest-flake8
-- configurationSources = {"pylint"},
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
