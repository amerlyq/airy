

--SRC: https://github.com/mfussenegger/nvim-dap
--  DEP: pacman -S python-debugpy
--USAGE:
-- * Setting breakpoints via :DapToggleBreakpoint or :lua require'dap'.toggle_breakpoint().
-- * Launching debug sessions and resuming execution via :DapNew and :DapContinue or :lua require'dap'.continue().
-- * Stepping through code via :DapStepOver, :DapStepInto or the corresponding functions :lua require'dap'.step_over() and :lua require'dap'.step_into().
-- * Inspecting the state:
--  = Via the built-in REPL: :lua require'dap'.repl.open()
--    - Try typing an expression followed by ENTER to evaluate it.
--    - Try commands like .help, .frames, .threads.
--    - Variables with structure can be expanded and collapsed with ENTER on the corresponding line.
--  = Via the widget UI (:help dap-widgets). Typically you'd inspect values, threads, stacktrace ad-hoc when needed instead of showing the information all the time, but you can also create sidebars for a permanent display
--  = Via UI extensions:
--    - IDE like: nvim-dap-ui
--    - Middle ground between the IDE like nvim-dap-ui and the built-in widgets: nvim-dap-view
--    - Show inline values: nvim-dap-virtual-text
-- See :help dap.txt, :help dap-mapping and :help dap-api.


--SRC: https://github.com/mfussenegger/nvim-dap-python
--INFO: Supported test frameworks are unittest, pytest and django.
--SEE: :help dap-python
--USAGE:
-- Call :lua require('dap').continue() to start debugging.
-- See :help dap-mappings and :help dap-api.
-- Use :lua require('dap-python').test_method() to debug the closest method above the cursor.


-- nnoremap <silent> <leader>dn :lua require('dap-python').test_method()<CR>
-- nnoremap <silent> <leader>df :lua require('dap-python').test_class()<CR>
-- vnoremap <silent> <leader>ds <ESC>:lua require('dap-python').debug_selection()<CR>

require("dap-python").setup("uv")
-- NEED:(must work in the shell): `python3 -m debugpy --version`
-- require("dap-python").setup("python3")
-- NEED:(must work in the shell): `/path/to/venv/bin/python -m debugpy --version`
-- require("dap-python").setup("/path/to/venv/bin/python")

--MAYBE:
-- require('dap-python').test_runner = 'pytest'
--
-- -- You can also add custom runners. An example in Lua:
-- local test_runners = require('dap-python').test_runners
-- -- `test_runners` is a table. The keys are the runner names like `unittest` or `pytest`.
-- -- The value is a function that takes two arguments:
-- -- The classnames and a methodname
-- -- The function must return a module name and the arguments passed to the module as list.
-- ---@param classnames string[]
-- ---@param methodname string?
-- test_runners.your_runner = function(classnames, methodname)
--   local path = table.concat({
--      table.concat(classnames, ":"),
--      methodname,
--   }, "::")
--   return 'modulename', {"-s", path}
-- end
--
-- require('dap-python').resolve_python = function()
--   return '/absolute/path/to/python'
-- end


-- table.insert(require('dap').configurations.python, {
--   type = 'python',
--   request = 'launch',
--   name = 'My custom launch configuration',
--
--   -- `program` is what you'd use in `python <program>` in a shell
--   -- If you need to run the equivalent of `python -m <module>`, replace
--   -- `program = '${file}` entry with `module = "modulename"
--   program = '${file}',
--
--   console = "integratedTerminal",
--
--   -- Other options:
--   -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
-- })
