local K = require'keys.bind'.K

--Create above/below empty line with auto indent
K('n', 'go', 'o<Space><Esc>^"_D')
K('n', 'gO', 'O<Space><Esc>^"_D')
K('n', 'K',  'a<CR><Right><Esc>')
K('n', '<C-k>', 'i<CR><Right><Esc>:m .-2<CR>')
K('n', '<C-j>', ':<C-u>+m.-<CR>J')


--Reindent
--USE: instead 'g<' -- ':mes' or ':norm! g<'
K('n', '>', '>>_')
K('n', '<', '<<_')
K('n', 'g>', '>')
K('n', 'g<', '<')
--Re-select visual block after indent
K('x', '>', '>gv|')
K('x', '<', '<gv')


--Duplicate current line
K('n', 'cC', ":t.<CR>", "dupl cur line")
K('x', 'C', ":t'><CR>")


--OFF: Add move line shortcuts
K('n', '<A-j>', ':m .+1<CR>==')
K('i', '<A-j>', '<Esc>:m .+1<CR>==gi')
K('v', '<A-j>', ':m \'>+1<CR>gv=gv')
K('i', '<A-k>', '<Esc>:m .-2<CR>==gi')
K('n', '<A-k>', ':m .-2<CR>==')
K('v', '<A-k>', ':m \'<-2<CR>gv=gv')
