
--Set colorscheme
vim.o.termguicolors = true

--SRC: https://github.com/ishan9299/nvim-solarized-lua.git
--ALT: 'shaunsingh/solarized.nvim'
vim.cmd [[colorscheme solarized]]
-- vim.g.solarized_disable_background = true
-- require('solarized').set()



--FIXED: wrong .py "def …" color
vim.highlight.link("TSKeywordFunction", "TSKeyword", true)

--FIXED: make 'listchars' hardly visible
-- vim.highlight.create('Whitespace', {ctermfg=0, ctermbg=8, guifg='#073642', guibg='#002b36', gui=nocombine}, false)
vim.highlight.create('Whitespace', {ctermfg=0, guifg='#072f3b'}, false)


--FIXED: dark „fissure“ on the left of linenumbers column
vim.highlight.link('SignColumn', 'LineNr', true)

-- [DiffAdd, DiffChange, DiffDelete, DiffText, SignColumn, LineNr, FoldColumn, SpecialKey]
-- vim.highlight.create('SignColumn', {ctermbg=NONE, guibg=NONE}, true)
