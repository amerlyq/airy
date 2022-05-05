
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
