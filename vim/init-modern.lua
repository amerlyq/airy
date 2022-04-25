-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

--SRC: https://github.com/lewis6991/impatient.nvim
require('impatient')
--USAGE :LuaCacheProfile
-- require('impatient').enable_profile()


-- TODO: ctags incremental re-generation
-- https://github.com/ludovicchabant/vim-gutentags
vim.g.gutentags_dont_load = true


--Set highlight on search
vim.o.hlsearch = true

vim.o.clipboard = 'unnamedplus'

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
vim.o.mouse = 'a'

--Enable break indent
vim.o.breakindent = true

--Save undo history
vim.opt.undofile = true

--Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

--Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

--Set colorscheme
vim.o.termguicolors = true
--SRC: https://github.com/ishan9299/nvim-solarized-lua.git
--ALT: 'shaunsingh/solarized.nvim'
vim.cmd [[colorscheme solarized]]
-- vim.g.solarized_disable_background = true
-- require('solarized').set()


vim.o.cursorline = true
vim.o.list = true
vim.opt.listchars = {tab='▸ ', trail='·', extends='»', precedes='«', nbsp='␣' }
-- vim.highlight.create('Whitespace', {ctermfg=0, ctermbg=8, guifg='#073642', guibg='#002b36', gui=nocombine}, false)
vim.highlight.create('Whitespace', {ctermfg=0, guifg='#072f3b'}, false)



-- EXPL: Add indentation guides even on blank lines
-- SRC: https://github.com/lukas-reineke/indent-blankline.nvim
-- FIXED: visual block selection uses "reverse" but plugin does not support that
-- FIXME: dunno how to "hi! link"
--   TRY: vim.highlight.link("TelescopeMatching", "Constant", true)
-- FUTURE:BET: reuse short func from there inof large buggy plugin below
--    ~/.cache/vim/dein/repos/github.com/nathanaelkane/vim-indent-guides/autoload/indent_guides.vim
-- OR:TRY: ⌇⡢⡥⢛⠵ https://github.com/glepnir/indent-guides.nvim

-- FIXED:WKRND: visually select indented space
--   SRC: https://github.com/lukas-reineke/indent-blankline.nvim/issues/328
-- vim.cmd([[hi! Visual cterm=None ctermfg=102 ctermbg=23 gui=None guifg=#586e75 guibg=#002b36 guisp=none ]])
-- vim.highlight.create('Visual', {cterm=None, ctermfg=102, ctermbg=242,
--   gui=None, guifg='#586e75', guibg='#002b36', guisp=None}, true)
-- vim.cmd([[hi! Visual guibg=#586e75 gui=None guifg=#002b36 ]])
vim.cmd([[hi! Visual cterm=None ctermbg=242 guibg=#839496 gui=None,nocombine guifg=#002b36 ]])



-- SEE:(blend): more virt_text display options by bfredl · Pull Request #14065 · neovim/neovim ⌇⡢⡥⢘⡞
--   https://github.com/neovim/neovim/pull/14065

-- vim.g.loaded_indent_blankline = 1
require("indent_blankline").setup {
  -- char = '┊',
  -- char = "",
  char = " ",
  -- filetype_exclude = { 'help', 'packer' },
  -- buftype_exclude = { 'terminal', 'nofile' },
  -- use_treesitter = true,
  -- show_current_context = true,
  -- show_trailing_blankline_indent = false,
  show_first_indent_level = false,
  -- char_highlight_list = { "IndentBlanklineOdd" },
  -- space_char_highlight_list = { "IndentBlanklineOdd", "IndentBlanklineEven" },
  -- space_char_blankline = " ",
}
vim.highlight.create('IndentBlanklineChar', {ctermfg=8, ctermbg=0, guifg='#002b36', guibg='#072f3b', gui=None}, false)
-- -- vim.highlight.create('IndentBlanklineSpaceChar', {gui='NONE'}, false)
-- -- vim.highlight.create('IndentBlanklineSpaceCharBlankline', {gui='NONE'}, false)
-- -- vim.highlight.create('IndentBlanklineContextChar', {gui='NONE'}, false)
-- vim.cmd([[
--   hi! IndentBlanklineChar gui=None
--   hi! IndentBlanklineSpaceChar gui=None
--   hi! IndentBlanklineSpaceCharBlankline gui=None
--   hi! IndentBlanklineContextChar gui=None
-- ]])



--Add move line shortcuts
vim.api.nvim_set_keymap('n', '<A-j>', ':m .+1<CR>==', { noremap = true})
vim.api.nvim_set_keymap('n', '<A-k>', ':m .-2<CR>==', { noremap = true})
vim.api.nvim_set_keymap('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { noremap = true})
vim.api.nvim_set_keymap('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { noremap = true})
vim.api.nvim_set_keymap('v', '<A-j>', ':m \'>+1<CR>gv=gv', { noremap = true})
vim.api.nvim_set_keymap('v', '<A-k>', ':m \'<-2<CR>gv=gv', { noremap = true})

-- @me
vim.api.nvim_set_keymap('i', ',s', '<Esc>:update<CR>', { noremap = true})
vim.api.nvim_set_keymap('i', ',ы', '<Esc>:update<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', ',s', ':<C-U>update<CR>', { noremap = true})
vim.api.nvim_set_keymap('v', ',s', ':<C-U>update<CR>', { noremap = true})
vim.api.nvim_set_keymap('n', ',d', ':<C-U>quit<CR>', { noremap = true})
vim.api.nvim_set_keymap('v', ',d', ':<C-U>quit<CR>', { noremap = true})

vim.api.nvim_set_keymap('n', '<F3>', [[
    :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
    \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
    \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
]], { noremap = true})


-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'


--Enable Comment.nvim
-- https://github.com/numToStr/Comment.nvim
-- require('Comment').setup()

--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ','
vim.g.maplocalleader = ' '  -- OR: "\<Space>"

--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

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
-- require('gitsigns').setup {
--   signs = {
--     add = { text = '+' },
--     change = { text = '~' },
--     delete = { text = '_' },
--     topdelete = { text = '‾' },
--     changedelete = { text = '~' },
--   },
-- }

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

--Add leader shortcuts
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers)
vim.keymap.set('n', '<leader>sf', function()
  require('telescope.builtin').find_files { previewer = false }
end)
vim.keymap.set('n', '<leader>sb', require('telescope.builtin').current_buffer_fuzzy_find)
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags)
vim.keymap.set('n', '<leader>st', require('telescope.builtin').tags)
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').grep_string)
vim.keymap.set('n', '<leader>sp', require('telescope.builtin').live_grep)
vim.keymap.set('n', '<leader>so', function()
  require('telescope.builtin').tags { only_current_buffer = true }
end)
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles)

--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor

-- Treesitter configuration
-- Highlight, edit, and navigate code using a fast incremental parsing library
-- Parsers must be installed manually via :TSInstall
--SRC: https://github.com/nvim-treesitter/nvim-treesitter
--SRC: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--ALSO:VIZ: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
  },
}

-- Make runtime files discoverable to the server
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')


-- NOTE: for jupyter buf mappings
vim.cmd([[
augroup MyAutoCmd
autocmd!
autocmd FileType c setlocal cindent
augroup END
]])

require 'plugins.lualine'
require 'plugins.cmp'
require 'plugins.python-lsp'

-- tnoremap <silent> <M-i> <C-\><C-n>:RnvimrResize<CR>
-- nnoremap <silent> <M-o> :RnvimrToggle<CR>
-- tnoremap <silent> <M-o> <C-\><C-n>:RnvimrToggle<CR>
vim.keymap.set({'n'}, '<S-Tab>', ':RnvimrToggle<CR>', {})
vim.keymap.set({'n'}, '<Tab>',   ':RnvimrToggle<CR>', {})
vim.keymap.set({'n'}, '<C-Tab>', ':RnvimrResize<CR>', {})

-- BUG:WTF: :verb map v -> "viÞ <Nop>" waiting pause
-- SRC: https://github.com/folke/which-key.nvim
require("which-key").setup {}

-- require("refactoring").setup({})
