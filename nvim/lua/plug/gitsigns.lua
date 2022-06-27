local K = require'keys.bind'.K

-- Gitsigns
-- Add git related info in the signs columns and popups
--DEP: plenary.nvim
--SRC: https://github.com/lewis6991/gitsigns.nvim
--USAGE:
-- :Gitsigns diffthis HEAD~1
-- :Gitsigns blame_line
-- :Gitsigns toggle_signs
-- :Gitsigns toggle_current_line_blame
-- :Gitsigns change_base ~
-- :Gitsigns reset_buffer
-- :Gitsigns change_base nil true
local M = require('gitsigns')
-- vim.opt.signcolumn = 'number'
M.setup {
  -- DONE: show gitsign as a color/bkgr of cur lineno (for narrow windows) ※⡢⢹⢓⠓※⡢⢹⢐⣓
  --   MAYBE:BET: chg numhl bg= inof fg=
  signcolumn = false, -- Toggle with `:Gitsigns toggle_signs`
  numhl      = true, -- Toggle with `:Gitsigns toggle_numhl`
  -- linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  -- word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  -- current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

-- DISABLE: [{'name': 'GitSignsAdd', 'numhl': 'false', 'texthl': 'GitSignsAdd', 'linehl': 'false'}]
-- config.signcolumn = false and config.numhl == false and config.linehl == false
-- and vim.wo.signcolumn == 'number'

K('n', ']c', M.next_hunk, "(gitsigns) next_hunk")
K('n', '[c', M.prev_hunk, "(gitsigns) prev_hunk")
