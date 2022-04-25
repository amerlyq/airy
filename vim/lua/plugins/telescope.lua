-- Telescope
--EXPL: UI to select things (files, grep results, open buffers...)
--SRC: https://github.com/nvim-telescope/telescope.nvim
--DEP: plenary.nvim
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native
-- https://github.com/nvim-telescope/telescope-fzf-native.nvim
--NEED: $ cd ... && make
require('telescope').load_extension 'fzf'

tsb = require('telescope.builtin')

--Add leader shortcuts
vim.keymap.set('n', '<Tab><Space>', tsb.buffers)
vim.keymap.set('n', '<Tab>f', (function() tsb.find_files {previewer=false} end))
vim.keymap.set('n', '<Tab>b', tsb.current_buffer_fuzzy_find)
vim.keymap.set('n', '<Tab>h', tsb.help_tags)
vim.keymap.set('n', '<Tab>t', tsb.tags)
vim.keymap.set('n', '<Tab>d', tsb.grep_string)
vim.keymap.set('n', '<Tab>p', tsb.live_grep)
vim.keymap.set('n', '<Tab>o', (function() tsb.tags {only_current_buffer=true} end))
vim.keymap.set('n', '<Tab>?', tsb.oldfiles)
