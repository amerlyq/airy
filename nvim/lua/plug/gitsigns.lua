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
M.setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

K('n', ']c', M.next_hunk, "(gitsigns) next_hunk")
K('n', '[c', M.prev_hunk, "(gitsigns) prev_hunk")
