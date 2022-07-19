local K = require'keys.bind'.K

--Remap space as leader key
-- vim.g.mapleader = ','
vim.g.mapleader = '\\'
vim.g.maplocalleader = ' ' -- OR: "\<Space>"

vim.keymap.set({'n','v'}, '<Space>', '<Nop>', { silent = true })


--Prevent triggering macros inof quoting
K('nx', 'Q', 'q')
K('nx', 'q', '<Nop>') -- TEMP: until surround enabled
