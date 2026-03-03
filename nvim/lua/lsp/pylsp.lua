-- DEPS: aur/python-lsp-all
--   NEED python-lsp-server, python-lsp-black, python-lsp-isort, python-lsp-mypy, python-pylsp-rope, python-pylint
--   OPT: python-pyflakes, python-mccabe, python-pycodestyle, python-pydocstyle,python-rope, flake8
--   ALSO: pip install pylsp-autoimport && auri python-autoimport

-- FIXME: should use folder from current buffer, instead of $PWD
local pjroot = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" })

-- VIZ: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
local settings = {
  -- NEED: nested "pylsp" dict
  --   TALK: https://github.com/neovim/nvim-lspconfig/issues/1347
  --   FIXED: https://neovim.discourse.group/t/pylsp-config-is-not-taken-into-account/1846/2
  pylsp = {

    -- ALT:DFL=pycodestyle
    --   FAIL: can't suppress file-wide errors like E266 "##" comments in !qute
    --   SRC:TALK: https://github.com/PyCQA/pycodestyle/issues/381
    -- DEPs: flake8 python-flake8-black python-flake8-docstrings python-flake8-isort python-flake8-typing-imports python-pytest-flake8
    -- configurationSources = {"flake8"},
    -- configurationSources = { "pylint" },

    plugins = {

      -- DISABLED:(use nvim-lint): orse pylsp is too slow, as it waits for mypy to finish
      -- BAD:NEED: $ paci nuspell
      pylint = { enabled = false }, -- , args = {"--rcfile=pylint.ini", "--disable C0301"}
      pylsp_mypy = {
        enabled = false,
        -- NOTE: You may need to run dmypy start in your project root once, though many plugins handle this for you.
        dmypy = true,
        live_mode = false,  -- works by writing your unsaved buffer to a temporary file and running mypy on that
        status_file = pjroot .. "/.dmypy.json",
        report_progress = true,
        -- overrides = { "--python-executable", "/d/miur/.venv/bin/python", true }
        -- overrides = { "--config-file", mypy_config, true }
        -- MAYBE? | This setting is required by pylsp-mypy for dynamic executable overrides.
        --   allow_dangerous_code_execution = true,
      },

      -- DEBUG: :lua =vim.lsp.get_clients({name='pylsp'})[1].config.settings.pylsp.plugins.jedi_definition
      -- OR: reproduce
      --   :lua vim.lsp.set_log_level('debug')
      --   Open your Python file and try "Go to Definition."
      --   :lua vim.cmd.edit(vim.lsp.get_log_path())
      jedi = {
        enabled = true,
        -- environment = "/d/miur/.venv",
        -- extra_paths = { vim.fn.getcwd() .. "/src" }, -- Adjust if src isn't the root
        -- environment = "/usr/bin/python", -- Force the Arch system python
      },
      -- Essential for "Go to Definition"
      --   FAIL: jedi still struggles with generics -- use !pyright OR use OLD style:
      --     NOK: def _try_cvt[T: Interpretable](cls: type[T]) -> T:
      --     OK: T = TypeVar("T", bound="Interpretable"); def _try_cvt(cls: type[T]) -> T:
      jedi_definition = {
        enabled = false,
        follow_imports = true,
        follow_builtin_imports = true,
      },
      -- Recommended for better navigation/completion
      jedi_completion = { enabled = true },
      -- jedi_rename = {enabled = false},
      jedi_hover = { enabled = true },
      jedi_references = { enabled = true },
      jedi_symbols = { enabled = true },

      -- Extended Refactoring (if pylsp-rope is installed)
      -- rope = { enabled = false },
      pylsp_rope = {
        enabled = true,
        ropeFolder = { pjroot .. "/.ropeproject" },
      },
      -- DEP: pylsp-autoimport
      -- FAIL: autoimport = { enabled = true },
      -- SRC: https://github.com/bageljrkhanofemus/dotfiles/blob/4a8d7e555ca96d0d4b17eda6ed37c68c7ec6a045/dot_config/nvim/lua/configs/lsp.lua
      -- WAIT https://github.com/python-lsp/python-lsp-server/pull/199
      -- NEED: $ pip install . --user
      -- DISABLED:ERR: code errors
      rope_autoimport = {
        enabled = true,
        memory_cache = true, -- Better performance
        completions = { enabled = true },
        code_actions = { enabled = true },
      },
      rope_rename = { enabled = true },
      -- rope_completion = { enabled = true },

      -- DISABLED: prevent diagnostics/formatting from here (Ruff/Mypy LSP will take over)
      isort = { enabled = false },
      -- SRC:WTF: https://github.com/neovim/nvim-lspconfig/issues/903
      -- formatCommand = {"black"}
      black = { enabled = false, cache_config = true },
      ruff = {
        enabled = false,
        live_mode = true, -- Shows errors as you type, before you even save
        extendSelect = { "I" }, -- "I" includes isort-like import sorting
        format = { "I" },       -- Ensures sorting is part of formatting
      },

      pydocstyle = { enabled = false },
      autopep8 = { enabled = false },
      yapf = { enabled = false },
      flake8 = { enabled = false },
      pycodestyle = { enabled = false, maxLineLength = 88 },
      pyflakes = { enabled = false },
      autoflake = { enabled = false },
      mccabe = { enabled = false },

      -- autopep8_format = {enabled = false},
      -- definition = {enabled = false},
      -- flake8_lint = {enabled = false},
      -- folding = {enabled = false},
      -- highlight = {enabled = false},
      -- hover = {enabled = false},
      -- mccabe_lint = {enabled = false},
      -- preload_imports = {enabled = false},
      -- pycodestyle_lint = {enabled = false},
      -- pydocstyle_lint = {enabled = false},
      -- pyflakes_lint = {enabled = false},
      -- pylint_lint = {enabled = false},
      -- references = {enabled = false},
      -- signature = {enabled = false},
      -- symbols = {enabled = false},
      -- yapf_format = {enabled = false},
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
  if next(overrides) then
    -- 3. Always add the true marker
    table.insert(overrides, true)
    settings.pylsp.plugins.pylsp_mypy.overrides = overrides
  end
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

-- BET: /w/g18-*/nvim-ruff.nou
-- Keep pylsp (The Brain): Enable only rope (for auto-imports) and the core
--   navigation features. Disable all its linting/formatting.
-- Use ruff-lsp (The Muscles): It is a standalone, Rust-powered server
--   (available on Arch as python-ruff-lsp or ruff). It is instantly responsive
--   and handles sorting, removing imports, and formatting.
-- Run Mypy via none-ls (The Specialist): Use none-ls only for Mypy. This keeps
--   the 10s delay completely isolated from your typing experience.

vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', '.git' },
  settings = {
    -- ALT: args = { 'check', '--cache-dir', vim.fn.expand('~/.cache/ruff_cache'), '--force-exclude', '--quiet', '--stdin-filename', function() return vim.api.nvim_buf_get_name(0) end }
    -- cacheDir = pjroot .. ".ruff_cache",
    cacheDir = vim.fn.expand('~/.cache/ruff'),
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
})
vim.lsp.enable('ruff')


-- If you are writing modern Python with generics, pylsp (Jedi) is honestly the
-- "wrong" tool for navigation. Most Neovim users in 2026 have moved to
-- BasedPyright for "Go to Definition" because it has 100% support for the
-- latest typing features.
vim.lsp.config('basedpyright', {
  -- cmd = { 'basedpyright-langserver', '--stdio' },
  -- filetypes = { 'python' },
  -- root_markers = { 'pyproject.toml', 'setup.py', '.git' },
  settings = {
    basedpyright = {
      analysis = {
        -- IMPORTANT: Disable diagnostics so it doesn't fight Mypy/Ruff
        -- typeCheckingMode = "off",
        typeCheckingMode = "basic", -- or "off" if you only want navigation
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
})
vim.lsp.enable('basedpyright')


-- DISABLED: I moved dmypy to nvim-lint
-- on_init_pyvenv_mypy(settings)

vim.lsp.config('pylsp', {
  -- cmd = { 'pylsp' },
  -- filetypes = { 'python' },
  -- root_markers = { 'pyproject.toml', '.git' },
  settings = settings
})
vim.lsp.enable('pylsp')
