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
      pylsp_mypy = { enabled = true,
        live_mode = false,  -- works by writing your unsaved buffer to a temporary file and running mypy on that
        report_progress = true,
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


-- WARN: may need to repeat inside on_attach()
--   WHY: to show mypy errors, if you open /d/todo and then from there some /d/project
local function on_init_pyvenv_mypy(settings, client)
  if client then
    -- NEW: = client.workspace_folders[1].name
    local root_dir = client.root_dir
  else
    -- OLD: = vim.lsp.buf.root_dir()
    -- OLD: = util.find_git_ancestor(vim.fn.expand('%:p')) or vim.loop.cwd()
    local root_markers = { ".git", "pyproject.toml", "setup.py", ".venv", "requirements.txt" }
    -- Get root for the current buffer (0)
    local project_root = vim.fs.root(0, root_markers)
    -- Fallback to current directory if no markers found
    local root_dir = project_root or vim.fn.getcwd()
  end

  -- Fallback: if no root_dir, use the directory of the current file
  local effective_root = root_dir or vim.fn.expand('%:p:h')
  local overrides = {
    -- "--show-column-numbers", -- CRITICAL for Neovim diagnostics
  }

  -- 1. Cache Override: Only if we are in a proper project (root_dir exists)
  if root_dir then
    table.insert(overrides, "--cache-dir")
    table.insert(overrides, vim.fn.fnamemodify(root_dir .. "/.mypy_cache", ":p"))
  end
  -- 2. Venv Detection: Only if the venv exists at the effective root
  local venv_python = vim.fn.fnamemodify(effective_root .. "/.venv/bin/python", ":p")
  if vim.fn.executable(venv_python) == 1 then
    table.insert(overrides, "--python-executable")
    table.insert(overrides, venv_python)
  end
  -- 3. Always add the true marker
  table.insert(overrides, true)

  settings.pylsp.plugins.pylsp_mypy.overrides = overrides
  -- client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {},
  --   { pylsp = { plugins = { pylsp_mypy = {
  --     enabled = true,
  --     live_mode = false,
  --     overrides = overrides,
  --     report_progress = true,
  --   } } }
  -- })
  -- client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })

  -- DEBUG:
  -- vim.schedule(function()
  --   print("pylsp-mypy: Configured with venv -> " .. venv_python)
  -- end)
  -- vim.defer_fn(function()
  --   print("AFTER: Pylint enabled is: " .. tostring(client.config.settings.pylsp.plugins.pylint.enabled))
  -- end, 500) -- wait 500ms
end

on_init_pyvenv_mypy(settings)

vim.lsp.config('pylsp', { settings = settings })

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
