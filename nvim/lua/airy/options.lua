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

--FIXME:FAIL:(once=true): only restore position on first opening
--ALT: https://github.com/vladdoster/remember.nvim
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = "(State) restore cursor position",
  command = 'silent! normal! g`"zv'
})

--Case insensitive searching UNLESS /C or capital in search
o.ignorecase = true
o.smartcase = true

--Decrease update time
o.updatetime = 1000
vim.wo.signcolumn = 'number'

o.cursorline = true
o.list = true
vim.opt.listchars = {tab='▸ ', trail='·', extends='»', precedes='«', nbsp='␣' }

-- Set completeopt to have a better completion experience
o.completeopt = 'menu,menuone,noselect'
o.whichwrap = '<,>,[,]'
