-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

--SRC: https://github.com/lewis6991/impatient.nvim
require('impatient')
--USAGE :LuaCacheProfile
-- require('impatient').enable_profile()

-- Make runtime files discoverable to the server
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

require 'cfg.colors'
require 'cfg.options'
require 'cfg.keys-remap'

--Enable Comment.nvim
-- https://github.com/numToStr/Comment.nvim
-- require('Comment').setup()

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Gitsigns
-- Add git related info in the signs columns and popups
--DEP: plenary.nvim
--SRC: https://github.com/lewis6991/gitsigns.nvim
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}


require 'plugins.lualine'
require 'plugins.cmp'
require 'plugins.python-lsp'

require 'plugins.guides'
require 'plugins.telescope'
require 'plugins.treesitter'

require("trouble").setup {
  icons=false,  -- NEED:DEP=nvim-web-devicons
  -- auto_open = true,
  auto_close = true,
  -- auto_fold = true,
  use_diagnostic_signs = true,
}


-- BUG:WTF: :verb map v -> "viÞ <Nop>" waiting pause
-- SRC: https://github.com/folke/which-key.nvim
require("which-key").setup {}

-- require("refactoring").setup({})


-- TEMP: for jupyter-vim.src.vim
vim.cmd([[
augroup MyAutoCmd
autocmd!
augroup END
]])
