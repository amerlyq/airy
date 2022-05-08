KE('x', 'v', 'mode() ==# "\\<C-v>" ? "v" : "\\<C-v>"')

--Reselect pasted visual selection
KE('n', 'gv', "'`[' . strpart(getregtype(), 0, 1) . '`]'")


-- ALT:SRC: https://github.com/yogeshdhamija/better-asterisk-remap.vim/blob/master/plugin/better-asterisk-remap.vim
-- nnoremap * :let old=@"<CR>yiw:let @/="\\V\\C\\<".escape(@", '/\')."\\>"<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
-- vnoremap * :<C-U>let old=@"<CR>gvy:let @/="\\V\\C".escape(@", '/\')<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
require 'seize.vsel'
-- DEBUG: vim.keymap.set('v', '*', '<Cmd>lua print(vim.inspect(getVisualSelection()))<CR>', nore)
-- vim.keymap.set('v', '*', (function() vim.fn.setreg("/", getVisualSelection(), "v") end), nore)
vim.keymap.set('v', '*', '<Cmd>lua vim.fn.setreg("/", getVisualSelection(), "v")<CR><Esc>n', { noremap = true })


-- Prevent Paste loosing the register source. Deleted available by "- reg.
--   http://stackoverflow.com/a/7797434/1147859
-- vnoremap <unique> p pgvy
-- vnoremap <unique> P Pgvy
--" SRC: neovim - Clipboard is reset after first paste in Visual Mode - Vi and Vim Stack Exchange ⌇⡠⡖⠑⢖
--   https://vi.stackexchange.com/questions/25259/clipboard-is-reset-after-first-paste-in-visual-mode
KE('v', 'p', "'pgv\"'.v:register.'y`>'")
KE('v', 'P', "'Pgv\"'.v:register.'y`>'")
-- noremap  <unique> zp "0p
-- noremap  <unique> zP "0P
