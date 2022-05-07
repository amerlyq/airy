-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

require 'cfg.colors'
require 'cfg.options'
require 'cfg.keys-remap'

require 'plugins.lualine'
require 'plugins.cmp'
require 'plugins.python-lsp'

require 'plugins.guides'
require 'plugins.telescope'
require 'plugins.treesitter'

-- TODO: ctags incremental re-generation
-- https://github.com/ludovicchabant/vim-gutentags
vim.g.gutentags_dont_load = true


require("trouble").setup {
  icons=false,  -- NEED:DEP=nvim-web-devicons
  -- auto_open = true,
  auto_close = true,
  -- auto_fold = true,
  use_diagnostic_signs = true,
}

-- BUG:WTF: :verb map v -> "viÞ <Nop>" waiting pause
-- SRC: https://github.com/folke/which-key.nvim
-- ALT: telescope.actions.which_key()
local presets = require("which-key.plugins.presets")
presets.operators[">"] = nil
presets.operators["<lt>"] = nil
require("which-key").setup {
  spelling = {
    enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
    suggestions = 20, -- how many suggestions should be shown in the list?
  },
}

-- require("refactoring").setup({})
