local K = require'keys.bind'.K

-- Make <C-L> (redraw screen) and turn off search hl until the next search
-- SRC: http://vim.wikia.com/wiki/Example_vimrc
K('', '<C-l>', '<Cmd>setl hlsearch! hls?<CR>')


K('nx', ',rd', 'g//d<CR>', "Delete matching lines")
K('nx', ',re', 's;;;g<CR>', "Erase matching words")
K('nx', ',rp', 's::<C-r>":g', "Replace by pasted register")
-- K('nx', ',ry', 's::<C-r>":g')


-- K('nx', ',rw', 's::<C-r><C-w>:g')
-- K('nx', ',r+', 's::<C-r>+:g')
-- K('nx', ',rm', 's;;<C-r>/;g')
-- K('nx', ',rv', '<C-u>s@@<C-r>=GetVisualSelection("")<CR>@g')
-- K('nx', ',rs', '<C-u>s@<C-r>=GetVisualSelection("")<CR>@@g')
-- K('nx', ',rf', 'v//d<CR>')
