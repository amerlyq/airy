local o, g = vim.o, vim.g
local K = require'keys.bind'.K

g.rnvimr_enable_picker = 1
-- g.rnvimr_shadow_winblend = 50

g.rnvimr_presets = {
  {width = 0.88, height = 0.88, col=0.06, row=0.06},
  {width = 0.96, height = 0.96, col=0.02, row=0.02},
  -- {width = 0.98, height = 0.50, col=0.01, row=0.01},
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
