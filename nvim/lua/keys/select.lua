
vim.keymap.set('x', 'v', 'mode() ==# "\\<C-v>" ? "v" : "\\<C-v>"', { expr = true, silent = true, noremap = true })

--Reselect pasted visual selection
vim.keymap.set('n', 'gv', "'`[' . strpart(getregtype(), 0, 1) . '`]'", { expr = true })
