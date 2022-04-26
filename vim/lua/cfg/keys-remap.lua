--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ','
vim.g.maplocalleader = ' ' -- OR: "\<Space>"
local nore = { noremap = true }


--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set('x', 'v', 'mode() ==# "\\<C-v>" ? "v" : "\\<C-v>"', { expr = true, silent = true, noremap = true })


--Prevent triggering macros inof quoting
vim.keymap.set({'n', 'v'}, 'Q', 'q', nore)
vim.keymap.set({'n', 'v'}, 'q', '<Nop>', nore) -- TEMP: until surround enabled


--Create above/below empty line with auto indent
vim.keymap.set('n', 'go', 'o<Space><Esc>^"_D', nore)
vim.keymap.set('n', 'gO', 'O<Space><Esc>^"_D', nore)
vim.keymap.set('n', 'K', 'a<CR><Right><Esc>', nore)


--Duplicate current line
vim.keymap.set('n', 'cC', ":t.<CR>", nore)
vim.keymap.set('x', 'C', ":t'><CR>", nore)


--Buffers switch
vim.keymap.set({ 'n', 'v' }, 'gh', ":<C-U>bprev<CR>", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'gl', ":<C-U>bnext<CR>", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'gH', ":<C-U>bfirst<CR>", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'gL', ":<C-U>blast<CR>", { noremap = true })


--Window switch
vim.keymap.set({ 'n', 'v' }, 'zh', "<C-W>h", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'zj', "<C-W>j", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'zk', "<C-W>k", { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'zl', "<C-W>l", { noremap = true })


--OFF: Add move line shortcuts
vim.api.nvim_set_keymap('n', '<A-j>', ':m .+1<CR>==', { noremap = true })
vim.api.nvim_set_keymap('n', '<A-k>', ':m .-2<CR>==', { noremap = true })
vim.api.nvim_set_keymap('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { noremap = true })
vim.api.nvim_set_keymap('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-j>', ':m \'>+1<CR>gv=gv', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-k>', ':m \'<-2<CR>gv=gv', { noremap = true })


--Buffers save/close/exit
vim.keymap.set('i', ',s', '<Esc>:update<CR>', { noremap = true })
vim.keymap.set('i', ',ы', '<Esc>:update<CR>', { noremap = true })
vim.keymap.set({ 'n', 'v' }, ',s', ':<C-U>update<CR>', { noremap = true })
-- " FIXED:(E173):SEE http://vim.1045645.n5.nabble.com/Re-how-to-suppress-quot-E173-1-more-file-to-edit-quot-td5716336.html#a5716344
-- " ALT: if argc()>1|sil blast|sil bfirst|en
-- set noconfirm   " abort action on unsaved for Qfast to work
vim.cmd [[com! -bar Qfast try|sil quit|catch/:E37/|conf quit
  \|catch/:E173/|try|sil qall|catch/E37/|conf qall|endt|endt]]
vim.keymap.set({ 'n', 'v' }, ',d', ':<C-U>Qfast<CR>', { noremap = true })
vim.keymap.set({ 'n', 'v' }, ',x', function()
  vim.cmd([[exe (bufnr('%') == bufnr('$') ? 'bprev' : 'bnext') .'|bdelete '. bufnr('%')]])
end, { noremap = true })


--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
vim.api.nvim_set_keymap('n', '<F3>', [[
:echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
\.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
\.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
]], { noremap = true })


--CFG plugins
vim.keymap.set('n', '<M-o>', ':RnvimrToggle<CR>', nore)
vim.keymap.set('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>', nore)
vim.keymap.set('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>', nore)
-- vim.keymap.set({ 'n' }, '<S-Tab>', ':RnvimrToggle<CR>', nore)
-- vim.keymap.set({ 'n' }, '<Tab>', ':RnvimrToggle<CR>', nore)
-- vim.keymap.set({ 'n' }, '<C-Tab>', ':RnvimrResize<CR>', {})

vim.keymap.set('n', '<Tab>q', ':TroubleToggle<CR>')
