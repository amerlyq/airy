
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
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}
