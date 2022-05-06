local K = require 'keys.K'

--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
K('n', '<F3>', ':packadd playground | TSHighlightCapturesUnderCursor<CR>')
-- K('n', '<F3>', [[
-- :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
-- \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
-- \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
-- ]])


--CFG plugins
K('n', '<M-o>', ':RnvimrToggle<CR>')
K('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>')
K('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>')
-- K('n', '<S-Tab>', ':RnvimrToggle<CR>')
-- K('n', '<Tab>', ':RnvimrToggle<CR>')
-- K('n', '<C-Tab>', ':RnvimrResize<CR>')

K('n', '<Tab>q', ':TroubleToggle<CR>')
