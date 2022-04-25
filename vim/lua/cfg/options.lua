
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

vim.o.cursorline = true
vim.o.list = true
vim.opt.listchars = {tab='▸ ', trail='·', extends='»', precedes='«', nbsp='␣' }

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'
