local K = require 'keys.bind'.K

-- Make <C-L> (redraw screen) and turn off search hl until the next search
-- SRC: http://vim.wikia.com/wiki/Example_vimrc
K('', '<C-l>', '<Cmd>setl hlsearch! hls?<CR>')


K('n', ',c', ':%s;;;g<Left><Left>', "Replace all matches by")
K('x', ',c', ':s;;;g<Left><Left>', "Replace matches in selected region by")
-- '<Leader>c' : 's;;<C-r>=(v:count ? substitute(string(v:count), '.', '\\&', 'g') : '')<CR>;g',
-- '<Leader>C' : 'g//'
-- '<Leader>R' : 'v//'

K('nx', ',rd', '<Cmd>g//d<CR>', "Delete matching lines")

K('n', ',re', '<Cmd>%s;;;g<CR>', "Erase matching words")
K('x', ',re', ':s;;;g<CR>', "Erase matching words")

K('n', ',rq', '<Cmd>%s;[\'"`«»„“];;g<CR>', "Erase quotes")
K('x', ',rq', ':s;[\'"`«»„“];;g<CR>', "Erase quotes")

--SRC: https://www.reddit.com/r/neovim/comments/44g53k/multi_cursor_in_neovim/
K('n', ',rw', "'<,'>g/^/norm ", "Rewrite by norm action")
K('x', ',rw', 'g/^/norm ', "Erase quotes")

K('n', ',ry', "<Cmd>%s;;<C-r>=escape(getreg('\"'),';')<CR>;g<CR>", "Replace by pasted register")
K('x', ',ry', ":s;;<C-r>=escape(getreg('\"'),';')<CR>;g<CR>", "Replace by pasted register")
-- K('nx', ',rp', ...


-- K('nx', ',rw', 's::<C-r><C-w>:g')
-- K('nx', ',r+', 's::<C-r>+:g')
-- K('nx', ',rm', 's;;<C-r>/;g')
-- K('nx', ',rv', '<C-u>s@@<C-r>=GetVisualSelection("")<CR>@g')
-- K('nx', ',rs', '<C-u>s@<C-r>=GetVisualSelection("")<CR>@@g')
-- K('nx', ',rf', 'v//d<CR>')
