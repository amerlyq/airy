local o, g = vim.o, vim.g
local K = require'keys.bind'.K

g.rnvimr_enable_picker = 1
-- g.rnvimr_shadow_winblend = 50

g.rnvimr_layout = {
  relative = 'editor',
  width= 0.88 * o.columns,
  height= 0.88 * o.lines,
  col= 0.06 * o.columns + 2,
  row= 0.06 * o.lines,
  style= 'minimal'
}

--OR: g.rnvimr_enable_ex = 1
vim.api.nvim_create_autocmd('BufEnter', {
  desc = "(Hack) open !ranger for directories",
  command = "if isdirectory(expand('<amatch>'))| call rnvimr#enter_dir(expand('<amatch>'), expand('<abuf>')) |en"
})

-- ALT: <Tab> <S-Tab> <C-Tab>
K('n', ',f', ':RnvimrToggle<CR>')
K('n', '<M-o>', ':RnvimrToggle<CR>')
K('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>')
K('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>')

--HACK: preload in background for better responsiveness
vim.defer_fn(function () vim.cmd('RnvimrStartBackground') end, 1000)
