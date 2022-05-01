-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

--SRC: https://github.com/lewis6991/impatient.nvim
-- require('impatient')
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

require('nvim_comment').setup {
  -- HACK: pull "commentstring" based on HEREDOC language
  -- hook = function()
  --   if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
  --     require("ts_context_commentstring.internal").update_commentstring()
  --   end
  -- end
}


-- ALT:SRC: https://github.com/yogeshdhamija/better-asterisk-remap.vim/blob/master/plugin/better-asterisk-remap.vim
-- nnoremap * :let old=@"<CR>yiw:let @/="\\V\\C\\<".escape(@", '/\')."\\>"<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
-- vnoremap * :<C-U>let old=@"<CR>gvy:let @/="\\V\\C".escape(@", '/\')<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
require 'seize.vsel'
-- DEBUG: vim.keymap.set('v', '*', '<Cmd>lua print(vim.inspect(getVisualSelection()))<CR>', nore)
-- vim.keymap.set('v', '*', (function() vim.fn.setreg("/", getVisualSelection(), "v") end), nore)
vim.keymap.set('v', '*', '<Cmd>lua vim.fn.setreg("/", getVisualSelection(), "v")<CR><Esc>n', nore)



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


-- TEMP: for jupyter-vim.src.vim
vim.cmd([[
augroup MyAutoCmd
autocmd!
augroup END
]])
