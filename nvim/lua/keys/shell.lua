local o, g = vim.o, vim.g
local K = require 'keys.bind'.K

o.makeprg = './ctl'

K('n', ',m', '<Cmd>up<Bar>make<Bar>cw<CR>')
K('n', ',M', '<Cmd>up<Bar>make<CR>')
