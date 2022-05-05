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
      -- n = {
      --   ['?'] = require('telescope').action_generate.which_key {
      --     name_width = 20, -- typically leads to smaller floats
      --     max_height = 0.5, -- increase potential maximum height
      --     separator = " > ", -- change sep between mode, keybind, and name
      --     close_with_action = false, -- do not close float on action
      --   },
      -- },
    },
  },
}

-- SEIZE: mentioned plugins in comment
-- lsp, pyls: how to get autocompletion and signatures of imported library : neovim ⌇⡢⡮⣓⢘
--   https://www.reddit.com/r/neovim/comments/m7zviy/lsp_pyls_how_to_get_autocompletion_and_signatures/

-- Enable telescope fzf native
-- https://github.com/nvim-telescope/telescope-fzf-native.nvim
--NEED: $ cd ... && make
require('telescope').load_extension 'fzf'

local B = require('telescope.builtin')

--Add leader shortcuts
vim.keymap.set('n', '<Tab><Space>', B.buffers)
vim.keymap.set('n', '<Tab><Tab>', B.resume)
vim.keymap.set('n', '<Tab>f', (function() B.find_files {previewer=false} end))
vim.keymap.set('n', '<Tab>b', B.current_buffer_fuzzy_find)
vim.keymap.set('n', '<Tab>g', B.git_status)
vim.keymap.set('n', '<Tab>G', B.git_bcommits)
vim.keymap.set('n', '<Tab>h', B.help_tags)
vim.keymap.set('n', '<Tab>t', B.tags)
vim.keymap.set('n', '<Tab>d', B.grep_string)
vim.keymap.set('n', '<Tab>p', B.live_grep)
vim.keymap.set('n', '<Tab>o', (function() B.tags {only_current_buffer=true} end))
vim.keymap.set('n', '<Tab>?', B.oldfiles)
