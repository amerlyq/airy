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


-- EXPL: Add indentation guides even on blank lines
-- SRC: https://github.com/lukas-reineke/indent-blankline.nvim
vim.highlight.create('IndentBlanklineOdd', {ctermfg=8, ctermbg=0, guifg='#002b36', guibg='#072f3b', gui=nocombine}, false)
vim.highlight.create('IndentBlanklineEven', {ctermfg=8, ctermbg=0, guifg='#002b36', guibg='#072f3b', gui=nocombine}, false)
-- vim.cmd [[highlight IndentBlanklineIndent1 guifg=#E06C75 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E5C07B gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent3 guifg=#98C379 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent4 guifg=#56B6C2 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent5 guifg=#61AFEF gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent6 guifg=#C678DD gui=nocombine]]

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
    char_highlight_list = { "IndentBlanklineOdd", "IndentBlanklineEven" },
    -- space_char_highlight_list = { "IndentBlanklineOdd", "IndentBlanklineEven" },
    -- space_char_blankline = " ",
    -- char_highlight_list = {
    --     "IndentBlanklineIndent1",
    --     "IndentBlanklineIndent2",
    --     "IndentBlanklineIndent3",
    --     "IndentBlanklineIndent4",
    --     "IndentBlanklineIndent5",
    --     "IndentBlanklineIndent6",
    -- },
}


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

--Set statusbar
--SRC: https://github.com/nvim-lualine/lualine.nvim
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
}

--Enable Comment.nvim
-- https://github.com/numToStr/Comment.nvim
-- require('Comment').setup()

--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

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


require 'plugins.python-lsp'
require 'plugins.luasnip'

-- require("refactoring").setup({})
