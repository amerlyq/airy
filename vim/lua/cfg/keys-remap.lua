-- WAIT:(merge): for "desc" param ⌇⡢⡮⢰⢋
--  https://github.com/folke/which-key.nvim/issues/242
local KG = vim.api.nvim_set_keymap  -- OR: vim.keymap.set
-- local KB = vim.api.nvim_buf_set_keymap(bufnr=0, m, lhs, rhs, opts)
-- ALT: https://github.com/folke/which-key.nvim/issues/267
function noremap(modes, lhs, rhs, desc)
  local opts = { noremap = true }
  if type(rhs) == "function" then
    opts.callback = rhs
    rhs = ''
  end
  for i = 1, #modes do
    KG(modes:sub(i,i), lhs, rhs, opts)
  end
end
local K = noremap


--Remap space as leader key
vim.g.mapleader = ','
vim.g.maplocalleader = ' ' -- OR: "\<Space>"
vim.keymap.set({'n','v'}, '<Space>', '<Nop>', { silent = true })


--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set('x', 'v', 'mode() ==# "\\<C-v>" ? "v" : "\\<C-v>"', { expr = true, silent = true, noremap = true })


--Prevent triggering macros inof quoting
K('nx', 'Q', 'q')
K('nx', 'q', '<Nop>') -- TEMP: until surround enabled


--Create above/below empty line with auto indent
K('n', 'go', 'o<Space><Esc>^"_D')
K('n', 'gO', 'O<Space><Esc>^"_D')
K('n', 'K',  'a<CR><Right><Esc>')


--Duplicate current line
K('n', 'cC', ":t.<CR>", "dupl cur line")
K('x', 'C', ":t'><CR>")

--Reselect pasted visual selection
vim.keymap.set('n', 'gv', "'`[' . strpart(getregtype(), 0, 1) . '`]'", { expr = true })

--Buffers switch
K('nx', 'gh', ":<C-U>bprev<CR>")
K('nx', 'gl', ":<C-U>bnext<CR>")
K('nx', 'gH', ":<C-U>bfirst<CR>")
K('nx', 'gL', ":<C-U>blast<CR>")


--Window switch
K('nx', 'zh', "<C-W>h")
K('nx', 'zj', "<C-W>j")
K('nx', 'zk', "<C-W>k")
K('nx', 'zl', "<C-W>l")

--Reindent
--USE: instead 'g<' -- ':mes' or ':norm! g<'
K('n', '>', '>>_')
K('n', '<', '<<_')
K('n', 'g>', '>')
K('n', 'g<', '<')
--Re-select visual block after indent
K('x', '>', '>gv|')
K('x', '<', '<gv')


--OFF: Add move line shortcuts
K('n', '<A-j>', ':m .+1<CR>==')
K('i', '<A-j>', '<Esc>:m .+1<CR>==gi')
K('v', '<A-j>', ':m \'>+1<CR>gv=gv')
K('i', '<A-k>', '<Esc>:m .-2<CR>==gi')
K('n', '<A-k>', ':m .-2<CR>==')
K('v', '<A-k>', ':m \'<-2<CR>gv=gv')


--Buffers save/close/exit
K('i', ',s', '<Esc>:update<CR>')
K('i', ',ы', '<Esc>:update<CR>')
K('nx', ',s', ':<C-U>update<CR>')
-- " FIXED:(E173):SEE http://vim.1045645.n5.nabble.com/Re-how-to-suppress-quot-E173-1-more-file-to-edit-quot-td5716336.html#a5716344
-- " ALT: if argc()>1|sil blast|sil bfirst|en
-- set noconfirm   " abort action on unsaved for Qfast to work
vim.cmd [[com! -bar Qfast try|sil quit|catch/:E37/|conf quit
  \|catch/:E173/|try|sil qall|catch/E37/|conf qall|endt|endt]]
K('nx', ',d', ':<C-U>Qfast<CR>')
K('nx', ',x', function()
  vim.cmd([[exe (bufnr('%') == bufnr('$') ? 'bprev' : 'bnext') .'|bdelete '. bufnr('%')]])
end)


--DEBUG
--SRC: https://github.com/nvim-treesitter/playground
--OPT: :packadd playground
--  <F3> :TSHighlightCapturesUnderCursor
K('n', '<F3>', [[
:echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
\.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
\.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
]])


--CFG plugins
K('n', '<M-o>', ':RnvimrToggle<CR>')
K('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>')
K('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>')
-- K('n', '<S-Tab>', ':RnvimrToggle<CR>')
-- K('n', '<Tab>', ':RnvimrToggle<CR>')
-- K('n', '<C-Tab>', ':RnvimrResize<CR>')

K('n', '<Tab>q', ':TroubleToggle<CR>')
