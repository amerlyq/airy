local K = require'keys.bind'.K

--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })


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


--Readline
-- inoremap <C-j> <C-o>:wq<CR>
-- inoremap        <C-A> <C-O>^
-- inoremap <expr> <C-E> col('.')>strlen(getline('.'))<bar><bar>pumvisible()?"\<Lt>C-E>":"\<Lt>End>"
-- inoremap <expr> <C-B> getline('.')=~'^\s*$'&&col('.')>strlen(getline('.'))?"0\<Lt>C-D>\<Lt>Esc>kJs":"\<Lt>Left>"
-- inoremap <expr> <C-F> col('.')>strlen(getline('.'))?"\<Lt>C-F>":"\<Lt>Right>"
-- inoremap <expr> <C-D> col('.')>strlen(getline('.'))?"\<Lt>C-D>":"\<Lt>Del>"
