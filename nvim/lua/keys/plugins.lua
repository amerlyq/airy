--[CFG plugins]
local o, g = vim.o, vim.g
local K = require 'keys.bind'.K


--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
-- K('n', '<F3>', ':packadd playground | TSHighlightCapturesUnderCursor<CR>')
K('n', '<F3>', function()
  vim.cmd 'packadd playground | TSHighlightCapturesUnderCursor'
  K('nx', '<F3>', '<Cmd>TSHighlightCapturesUnderCursor<CR>', "Show :hl group under cursor")
end, "Show :hl group under cursor")


-- Align paragraphs by patt {{{1
--SRC: https://github.com/junegunn/vim-easy-align
--ALT: https://github.com/tommcdo/vim-lion
--OLD:(shitty syntax): 'godlygeek/tabular'
--DEP: 'vim-repeat'
--LIOR
--  CTRL-F  filter  Input string ([gv]/.*/?)
--  CTRL-I  indentation shallow, deep, none, keep
--  CTRL-L  left_margin Input number or string
--  CTRL-R  right_margin  Input number or string
--  CTRL-D  delimiter_align left, center, right
--  CTRL-U  ignore_unmatched  0, 1
--  CTRL-G  ignore_groups [], ['String'], ['Comment'], ['String', 'Comment']
--  CTRL-A  align Input string (/[lrc]+\*{0,2}/)
--  <Left>  stick_to_left { 'stick_to_left': 1, 'left_margin': 0 }
--  <Right> stick_to_left { 'stick_to_left': 0, 'left_margin': 1 }
--  <Down>  *_margin  { 'left_margin': 0, 'right_margin': 0 }
K('nx', 'gy', '<Plug>(EasyAlign)')
K('nx', 'gY', '<Plug>(LiveEasyAlign)')


-- LIOR:  HiSet=f<CR>  HiErase=f<BS>  HiClear=f<C-L>  HiFind=f<Tab>
-- SRC: https://github.com/azabiong/vim-highlighter
-- ALT:BET? https://github.com/inkarkat/vim-mark
--   VIZ: contains many links to all other plugins
-- OLD: https://github.com/t9md/vim-quickhl

-- SRC: https://github.com/ghillb/cybu.nvim
K("n", "<C-Tab>", "<Plug>(CybuPrev)")
K("n", "<S-Tab>", "<Plug>(CybuNext)")

-- ALT: vimscript
-- https://github.com/preservim/tagbar
-- https://github.com/liuchengxu/vista.vim
K('nx', '<Tab>t', '<Cmd>SymbolsOutline<CR>')


-- ALT:BET? usability
--   TALK https://www.reddit.com/r/neovim/comments/qk7uk1/telescope_pluginextension_that_lets_you_visit/hj31c50/?context=3
-- https://github.com/simnalamburt/vim-mundo
K('nx', '<Tab>u', '<Cmd>UndotreeToggle<CR>')


K('nx', '<Tab>q', '<Cmd>TroubleToggle<CR>')


-- SRC: https://github.com/AndrewRadev/switch.vim
g.switch_mapping = '<CR>'
g.switch_reverse_mapping = '<BS>'


-- Switch between alternative files [c,cpp,cxx,cc] <-> [h,hpp]
-- EXPL:(no <unique>) overrides my STD 'cycle through'
g.loaded_altr = 1
K('', ']f', '<Cmd>call altr#forward()<CR>')
K('', '[f', '<Cmd>call altr#back()<CR>')
-- command! -bar -nargs=0  A  call altr#forward()
vim.cmd [[
  call altr#define('%/src/%.c', '%/inc/%.h')
  call altr#define('%/source/%.cpp', '%/include/%.hpp', '%/include/%.h')
  call altr#define('%/src/%.cpp', '%/inc/%.h', '%/t/%_test.cpp')
]]
