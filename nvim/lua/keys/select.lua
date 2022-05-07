
vim.keymap.set('x', 'v', 'mode() ==# "\\<C-v>" ? "v" : "\\<C-v>"', { expr = true, silent = true, noremap = true })

--Reselect pasted visual selection
vim.keymap.set('n', 'gv', "'`[' . strpart(getregtype(), 0, 1) . '`]'", { expr = true })


-- ALT:SRC: https://github.com/yogeshdhamija/better-asterisk-remap.vim/blob/master/plugin/better-asterisk-remap.vim
-- nnoremap * :let old=@"<CR>yiw:let @/="\\V\\C\\<".escape(@", '/\')."\\>"<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
-- vnoremap * :<C-U>let old=@"<CR>gvy:let @/="\\V\\C".escape(@", '/\')<CR>:set hlsearch<CR>:let @"=old<CR>:redraw!<CR>:echo "/".@/<CR>
require 'seize.vsel'
-- DEBUG: vim.keymap.set('v', '*', '<Cmd>lua print(vim.inspect(getVisualSelection()))<CR>', nore)
-- vim.keymap.set('v', '*', (function() vim.fn.setreg("/", getVisualSelection(), "v") end), nore)
vim.keymap.set('v', '*', '<Cmd>lua vim.fn.setreg("/", getVisualSelection(), "v")<CR><Esc>n', { noremap = true })



