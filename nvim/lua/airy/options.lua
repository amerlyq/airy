-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
local o, g = vim.opt, vim.g

--Set highlight on search
o.hlsearch = true

o.clipboard = 'unnamedplus'

-- DISABLED: inherits "r.sh" from ranger which accesses too much files
o.shell = '/bin/sh'

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
o.mouse = 'a'

--Enable break indent
o.breakindent = true

--Save undo history
vim.opt.undofile = true

--Case insensitive searching UNLESS /C or capital in search
o.ignorecase = true
o.smartcase = true

--Decrease update time for write(swap) and CursorHold
o.updatetime = 1000
--DISABLED('number'): I'm used to detect LSP finished loading by the time when column appears
vim.wo.signcolumn = 'auto'

o.cursorline = true
o.list = true
vim.opt.listchars = { tab = '▸ ', trail = '·', extends = '»', precedes = '«', nbsp = '␣' }

-- Set completeopt to have a better completion experience
o.completeopt = 'menuone,noselect' -- menu,
o.whichwrap = '<,>,[,]'


-- set foldenable
-- set foldcolumn=2        " fold levels ruler on left (clickable)
-- "set foldmethod=manual  " <expr|syntax|marker> -- syntax defines folds
o.foldlevel = 99 -- close folds below this depth, initially
-- set foldlevelstart=99   " close folds below this depth, on enter
-- " set foldopen=all      " open on cursor touch, DISABLED: prevents 'za' fold
-- set fillchars=fold:\    " don't place extra dashes on scr right after foldtext
