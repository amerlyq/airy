local g = vim.g
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
g.rnvimr_enable_picker = 1
--OR: g.rnvimr_enable_ex = 1
vim.api.nvim_create_autocmd('BufEnter', {
  desc = "(Hack) open !ranger for directories",
  command = "if isdirectory(expand('<amatch>'))| call rnvimr#enter_dir(expand('<amatch>'), expand('<abuf>')) |en"
})
K('n', ',f', ':RnvimrToggle<CR>')
K('n', '<M-o>', ':RnvimrToggle<CR>')
K('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>')
K('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>')
-- K('n', '<S-Tab>', ':RnvimrToggle<CR>')
-- K('n', '<Tab>', ':RnvimrToggle<CR>')
-- K('n', '<C-Tab>', ':RnvimrResize<CR>')

K('n', '<Tab>q', ':TroubleToggle<CR>')
