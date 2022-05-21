local o, g = vim.o, vim.g
local K = require 'keys.bind'.K


K('n', ',tl', "<Cmd>let &showtabline=(&stal<2?2:1)<CR>")


-- K('n', '<F3>', [[
-- :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
-- \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
-- \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
-- ]])
