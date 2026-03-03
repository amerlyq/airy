
local lint = require('lint')

-- HACK: get the root_dir from the first active LSP client attached to this buffer
-- local function get_root()
--   local client = vim.lsp.get_clients({ bufnr = 0 })[1]
--   return (client and client.config.root_dir) or vim.uv.cwd()
-- end

-- ALT-1: Get markers from the built-in lspconfig (no need to maintain your own list)
-- local python_markers = require('lspconfig.configs.pyright').default_config.root_dir_patterns
-- Usually: { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pipfile", "pyrightconfig.json", ".git" }
-- local pjroot = vim.fs.root(0, python_markers) or vim.uv.cwd()
-- ALT-2:
-- local util = require('lspconfig.util')
-- Use the same logic the LSP uses to find the root
-- local pjroot = util.root_pattern(unpack(python_markers))(vim.api.nvim_buf_get_name(0))

-- 1. Identify your project root
local pjroot = vim.fs.root(0, { '.git', 'pyproject.toml' }) or vim.fn.getcwd()

-- DEBUG: :lua print(vim.inspect(require('lint').linters.dmypy))
local args = {
  -- ALT:(.gitignore): pjroot .. '/.dmypy.json'
  '--status-file', '/tmp/dmypy-' .. vim.fn.sha256(pjroot):sub(1, 8) .. '.json',
  'run',
  '--',
  -- INFO: use shared cache to avoid pollution everywhere
  '--cache-dir', vim.fn.expand('~/.cache/mypy_cache'),
  '--show-column-numbers',
  '--show-error-end',
  '--hide-error-context',
  '--no-color-output',
  '--no-error-summary',
  -- '--no-pretty',
  -- '--ignore-missing-imports',
  -- '--follow-imports=silent',
  -- '--hide-error-codes',
  -- '--no-color',
  -- '--no-error-summary',
}

local venv_python = pjroot .. "/.venv/bin/python"
if vim.fn.executable(venv_python) == 1 then
  table.insert(args, '--python-executable')
  table.insert(args, venv_python)
end

lint.linters.dmypy.args = args

-- lint.linters.pylint.cmd = 'python'
-- lint.linters.pylint.args = { '-m', 'pylint', '-f', 'json' }

-- Assign it to python files
lint.linters_by_ft = {
  python = { 'dmypy', 'pylint' },
}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
  callback = function()
    -- try_lint without arguments runs the linters defined in `linters_by_ft`
    -- for the current filetype
    require("lint").try_lint()

    -- You can call `try_lint` with a linter name or a list of names to always
    -- run specific linters, independent of the `linters_by_ft` configuration
    -- require("lint").try_lint("cspell")
  end,
})

-- 2. Hot-start dmypy on Project Entry
-- To avoid the "first run" lag, we trigger a background start when you open a Python file.
-- This ensures the daemon is warming up while you're still typing your first lines.
-- lua
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "python",
--   callback = function()
--     -- Start the daemon in the background if it's not running
--     -- 'dmypy start' is idempotent; it won't break if already running
--     vim.fn.jobstart({ "dmypy", "start" }, { detach = true })
--   end,
-- })


-- Conform is the successor to none-ls for formatting.
-- It's strictly for "making things pretty" and is extremely stable.
-- require("conform").setup({
--   formatters_by_ft = {
--     -- Ruff handles both layout and import sorting
--     python = { "ruff_organize_imports", "ruff_format" },
--   },
--   format_on_save = { timeout_ms = 500 },
-- })
