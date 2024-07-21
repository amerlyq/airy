--[CFG plugins]
local o, g = vim.o, vim.g
local K = require 'keys.bind'.K


--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
-- K('n', '<F3>', ':packadd playground | TSHighlightCapturesUnderCursor<CR>')
-- News - Neovim docs ⌇⡥⣆⠱⠹
--   https://neovim.io/doc/user/news.html#news-breaking
--   NOTE: Renamed vim.treesitter.playground to vim.treesitter.dev.
-- BET:(new):USE: :Inspect | :InspectTree
--   REF: https://github.com/nvim-treesitter/nvim-treesitter/issues/1228
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

-- https://github.com/preservim/tagbar
-- ALSO:SEE: TagbarOpenAutoClose, TagbarTogglePause, TagbarShowTag
K('nx', '<Tab>t', '<Cmd>TagbarToggle<CR>')
-- ALT: https://github.com/simrat39/symbols-outline.nvim
K('nx', '<Tab>T', '<Cmd>SymbolsOutline<CR>')
-- ALT: https://github.com/liuchengxu/vista.vim
-- WTF: https://github.com/glepnir/lspsaga.nvim


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

-- OR: use \dl \dr -- to merge with \df \ds submode
K('n', '\\l', '<Cmd>LinediffReset<CR>')
K('x', '\\l', ':Linediff<CR>')



-- SRC: https://github.com/dhruvasagar/vim-table-mode
-- NOTE: starts creating table as soon as you type <i C-k vv> '│'
-- g.table_mode_always_active = 1
-- g.table_mode_map_prefix = '<Leader>t'
g.table_mode_corner = '┼'
-- g.table_mode_corner_corner = '┐'
-- FAIL: during insert treats unicode as single-byte len
-- g.table_mode_separator = '│'
g.table_mode_fillchar = '─'
g.table_mode_header_fillchar = '─'


-- DEBUG: lazy keymap
-- vim.keymap.set("x", "X", function() require('substitute.exchange').visual() end, { noremap = true })

-- SRC: https://github.com/AndrewRadev/splitjoin.vim
g.splitjoin_join_mapping = '<Leader>J'
g.splitjoin_split_mapping = '<Leader>K'



-- SRC: https://github.com/chrisgrieser/nvim-spider
-- OLD:ALT: https://github.com/bkad/CamelCaseMotion
--   ALSO: ...
-- OR: "<cmd>lua require('spider').motion('b')<CR>",
K("nox", ",w", function() require('spider').motion('w') end, "Spider-w")
K("nox", ",e", function() require('spider').motion('e') end, "Spider-e")
K("nox", ",b", function() require('spider').motion('b') end, "Spider-b")
K("nox", ",ge", function() require('spider').motion('ge') end, "Spider-ge")


-- SUM: Converts snake/camel case of joined words {{{1
-- SRC: https://github.com/tyru/operator-camelize.vim
-- ALT:TUT: Switching Between camelCase and snake_case in Neovim using Lua - DEV Community ⌇⡦⢎⢎⠡
--   https://dev.to/dimaportenko/switching-between-camelcase-and-snakecase-in-neovim-using-lua-3ah7
K('', ',~', '<Plug>(operator-camelize-toggle)', "Camelize/Toggle")


-- SRC: https://github.com/jeetsukumaran/vim-indentwise
K('', '[,', '<Plug>(IndentWisePreviousLesserIndent)', 'indent/prev<')
K('', '[/', '<Plug>(IndentWisePreviousEqualIndent)', 'indent/prev=')
K('', '[.', '<Plug>(IndentWisePreviousGreaterIndent)', 'indent/prev>')
K('', '],', '<Plug>(IndentWiseNextLesserIndent)', 'indent/next<')
K('', ']/', '<Plug>(IndentWiseNextEqualIndent)', 'indent/next=')
K('', '].', '<Plug>(IndentWiseNextGreaterIndent)', 'indent/next>')
K('', '[_', '<Plug>(IndentWisePreviousAbsoluteIndent)', 'indent/prev!')
K('', ']_', '<Plug>(IndentWiseNextAbsoluteIndent)', 'indent/next!')
K('', '[<Space>', '<Plug>(IndentWiseBlockScopeBoundaryBegin)', 'indent/.beg')
K('', ']<Space>', '<Plug>(IndentWiseBlockScopeBoundaryEnd)', 'indent/.end')


-- SRC: https://github.com/machakann/vim-swap
g.swap_no_default_key_mappings = 1
K('n', ',ga', '<Plug>(swap-prev)', 'swap/prev')
K('n', ',gA', '<Plug>(swap-next)', 'swap/next')
K('nx', ',a', '<Plug>(swap-interactive)', 'swap/MODE')  -- OR: 'g<C-a>'
K('ox', 'i,', '<Plug>(swap-textobject-i)', 'swap/textobj-i')
K('ox', 'a,', '<Plug>(swap-textobject-a)', 'swap/textobj-a')


-- SRC: https://github.com/AndrewRadev/sideways.vim
K('n', 'ga', '<Plug>SidewaysLeft', 'sideways/left')
K('n', 'gA', '<Plug>SidewaysRight', 'sideways/right')
K('ox', 'ia', '<Plug>SidewaysArgumentTextobjI', 'sideways/textobj-i')
K('ox', 'aa', '<Plug>SidewaysArgumentTextobjA', 'sideways/textobj-a')
K('n', '[a', '<Cmd>SidewaysJumpLeft<CR>', 'sideways/jump-left')
K('n', ']a', '<Cmd>SidewaysJumpRight<CR>', 'sideways/jump-right')
-- <Plug>SidewaysArgumentInsertBefore
-- <Plug>SidewaysArgumentAppendAfter
K('n', 'ga', '<Plug>SidewaysArgumentInsertFirst', 'sideways/insert-first')
K('n', 'ga', '<Plug>SidewaysArgumentAppendLast', 'sideways/insert-last')



--OFF:TUT: https://github.com/ggandor/leap.nvim
--LIOR: s|S char1 char2 <space>? (<space>|<tab>)* label?
-- require('leap').set_default_keymaps()
-- -- Define equivalence classes for brackets and quotes, in addition to the default whitespace group.
-- require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
-- -- Override some old defaults - use backspace instead of tab (see issue #165).
-- require('leap').opts.special_keys.prev_target = '<backspace>'
-- require('leap').opts.special_keys.prev_group = '<backspace>'
-- -- Use the traversal keys to repeat the previous motion without explicitly invoking Leap.
-- require('leap.user').set_repeat_keys('<enter>', '<backspace>')
-- vim.cmd [[ autocmd ColorScheme * lua require('leap').init_highlight(true) ]]
K('n',  's', '<Plug>(leap)')
K('n',  'S', '<Plug>(leap-from-window)')
K('xo', 's', '<Plug>(leap-forward)')
K('xo', 'S', '<Plug>(leap-backward)')



-- SRC: https://github.com/embear/vim-foldsearch
-- g.foldsearch_highlight = 1
g.foldsearch_disable_mappings = 1
vim.cmd 'com! Fv let w:foldsearch_pattern = "\\V\\^\\%(\\%(".@/."\\)\\@!\\.\\)\\*\\$"|call foldsearch#foldsearch#FoldSearchDo()'
