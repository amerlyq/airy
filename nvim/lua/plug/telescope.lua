-- Telescope
--EXPL: UI to select things (files, grep results, open buffers...)
--SRC: https://github.com/nvim-telescope/telescope.nvim
--DEP: plenary.nvim

require('telescope').setup {
  defaults = {
    layout_strategy = 'vertical',
    -- layout_config = { height = 0.95 },
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = "close",
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

local T = require('telescope.builtin')
local KG = vim.api.nvim_set_keymap
local Kn = function(lhs, fn, s) KG('n', lhs, '', { callback = fn, noremap = true, desc = s }) end

--Add leader shortcuts
Kn('<Tab><CR>', T.builtin, "T.builtins")
Kn('<Tab><Space>', T.buffers, "T.buffers")
Kn('<Tab><Tab>', T.resume, "T.resume")
Kn('<Tab>?', T.oldfiles, "T.oldfiles")

Kn('<Tab>b', T.current_buffer_fuzzy_find, "T.fuzzy_buf")
Kn('<Tab>c', T.tags, "tags [T]")
Kn('<Tab>d', T.diagnostics, "T.diagnostics")
Kn('<Tab>f', (function() T.find_files { previewer = false } end), "T.find_files")
Kn('<Tab>g', T.git_status, "T.git_status")
Kn('<Tab>G', T.git_bcommits, "T.git_bcommits")
Kn('<Tab>h', T.help_tags, "T.help_tags")
Kn('<Tab>j', T.jumplist, "T.jumplist")
Kn('<Tab>l', T.lsp_document_symbols, "lsp_document_symbols [T]")
Kn('<Tab>m', T.oldfiles, "T.oldfiles")
Kn('<Tab>o', (function() T.tags { only_current_buffer = true } end), "T.tags_buf")
Kn('<Tab>q', T.quickfix, "T.quickfix")
Kn('<Tab>r', T.live_grep, "T.live_grep (rg)")
Kn('<Tab>s', T.grep_string, "T.grep_string (fuzzy)")
Kn('<Tab>k', T.tagstack, "T.tagstack")
