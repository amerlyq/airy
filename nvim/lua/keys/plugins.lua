local o, g = vim.o, vim.g
local K = require 'keys.bind'.K


K('n', ',tl', "<Cmd>let &showtabline=(&stal<2?2:1)<CR>")


--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
-- K('n', '<F3>', ':packadd playground | TSHighlightCapturesUnderCursor<CR>')
K('n', '<F3>', function()
  vim.cmd 'packadd playground | TSHighlightCapturesUnderCursor'
  K('nx', '<F3>', '<Cmd>TSHighlightCapturesUnderCursor<CR>', "Show :hl group under cursor")
end, "Show :hl group under cursor")

-- K('n', '<F3>', [[
-- :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
-- \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
-- \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
-- ]])


--[CFG plugins]

-- ALT: vimscript
-- https://github.com/preservim/tagbar
-- https://github.com/liuchengxu/vista.vim
K('nx', '<Tab>t', '<Cmd>SymbolsOutline<CR>')

-- ALT:BET? usability
--   TALK https://www.reddit.com/r/neovim/comments/qk7uk1/telescope_pluginextension_that_lets_you_visit/hj31c50/?context=3
-- https://github.com/simnalamburt/vim-mundo
K('nx', '<Tab>u', '<Cmd>UndotreeToggle<CR>')

K('nx', '<Tab>q', '<Cmd>TroubleToggle<CR>')
