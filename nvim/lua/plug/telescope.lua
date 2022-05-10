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
        ['<C-j>'] = "move_selection_next",
        ['<C-k>'] = "move_selection_previous",
      },
      n = {
        ['q'] = "close",
      --   ['?'] = require('telescope').action_generate.which_key {
      --     name_width = 20, -- typically leads to smaller floats
      --     max_height = 0.5, -- increase potential maximum height
      --     separator = " > ", -- change sep between mode, keybind, and name
      --     close_with_action = false, -- do not close float on action
      --   },
      },
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
local KG = vim.api.nvim_set_keymap
local Kn = function(lhs, fn) KG('n', lhs, '', { callback=fn, noremap=true }) end

--Add leader shortcuts
Kn('<Tab><CR>', B.builtin)
Kn('<Tab><Space>', B.buffers)
Kn('<Tab><Tab>', B.resume)

Kn('<Tab>f', (function() B.find_files {previewer=false} end))
Kn('<Tab>b', B.current_buffer_fuzzy_find)
Kn('<Tab>g', B.git_status)
Kn('<Tab>G', B.git_bcommits)
Kn('<Tab>h', B.help_tags)
Kn('<Tab>t', B.tags)
Kn('<Tab>d', B.grep_string)
Kn('<Tab>p', B.live_grep)
Kn('<Tab>o', (function() B.tags {only_current_buffer=true} end))
Kn('<Tab>?', B.oldfiles)
