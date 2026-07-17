
local lint = require('lint')

-- Assign it to python files
lint.linters_by_ft = {
  -- UNUSED:(too slow and somewhat useless -- run them from cli):
  --   { ..., "opengrep", "refurb" }
  -- DISABLED: too cpu-intensive with little benefits over basedpyright and ruff
  --   >> run them separately before commit inof on each save
  -- python = { 'dmypy', 'pylint' },
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

-- TODO: remove from mypy/pylint everything already covered by ruff/basedpyright
-- DEBUG: :lua print(vim.inspect(require('lint').linters.dmypy))
local dmypyargs = {
  -- ALT:(.gitignore): pjroot .. '/.dmypy.json'
  '--status-file', '/tmp/dmypy-' .. vim.fn.sha256(pjroot):sub(1, 8) .. '.json',
  'run',
  '--timeout', '50000',
  '--',
  -- INFO: use shared cache to avoid pollution everywhere
  '--cache-dir', vim.fn.expand('~/.cache/mypy_cache'),
  '--show-column-numbers',
  '--show-error-end',
  '--hide-error-context',
  '--no-color-output',
  '--no-error-summary',
  '--no-pretty',
  -- '--ignore-missing-imports',
  -- '--follow-imports=silent',
  -- '--hide-error-codes',
  -- '--no-color',
  -- '--no-error-summary',
  -- '--python-executable', vim.fn.exepath('python3')
}

local venv_python = pjroot .. "/.venv/bin/python"
if vim.fn.executable(venv_python) == 1 then
  table.insert(dmypyargs, '--python-executable')
  table.insert(dmypyargs, venv_python)

  -- ALT:
  -- table.insert(pylintargs, '--init-hook')
  -- table.insert(pylintargs, "import pylint_venv; pylint_venv.inithook()")
  lint.linters.pylint.cmd = venv_python
  local orig = lint.linters.pylint.args
  local pylintargs = { '-m', 'pylint' }
  lint.linters.pylint.args = vim.list_extend(pylintargs, orig)
end

lint.linters.dmypy.args = dmypyargs


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


-- 2. Define custom parser for Refurb (since it isn't built into nvim-lint)
lint.linters.refurb = {
  cmd = "refurb",
  stdin = false, -- Refurb reads files from disk
  append_fname = true,
  stream = "stdout",
  ignore_exitcode = true,
  args = { "--quiet" },
  parser = require("lint.parser").from_pattern(
    -- Refurb error pattern format: path/to/file.py:line:col: [code] description
    "^([^:]+):(%d+):(%d+):%s+(.*)$",
    { "file", "lnum", "col", "message" },
    nil,
    { ["source"] = "refurb" }
  ),
}

-- 2. Explicitly define Opengrep (leveraging identical JSON structure to Semgrep)
lint.linters.opengrep = {
  cmd = "opengrep",
  stdin = false,
  append_fname = true,
  stream = "stdout",
  ignore_exitcode = true,
  -- Uses local auto-discovery rules and outputs clean json format
  args = { "scan", "--config", "auto", "--json", "$FILENAME" },
  parser = function(output, bufnr)
    local status, decoded = pcall(vim.json.decode, output)
    if not status or not decoded or not decoded.results then
      return {}
    end

    local diagnostics = {}
    for _, item in ipairs(decoded.results) do
      table.insert(diagnostics, {
        source = "opengrep",
        lnum = (item.start.line or 1) - 1,
        col = (item.start.col or 1) - 1,
        end_lnum = (item["end"].line or 1) - 1,
        end_col = (item["end"].col or 1) - 1,
        severity = item.extra.severity == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
        message = ("[%s] %s"):format(item.check_id, item.extra.message),
      })
    end
    return diagnostics
  end,
}
