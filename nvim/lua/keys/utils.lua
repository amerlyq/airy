local o, g = vim.o, vim.g
local K = require 'keys.bind'.K


K('n', ',tl', "<Cmd>let &showtabline=(&stal<2?2:1)<CR>")
-- ALT: [Toggle]w
-- setl wrap! wrap?\|if exists('&bri')\|setl bri!\|endif<CR>
K('n', ',ts', "<Cmd>setl spell! spelllang=en_us,ru_yo,uk spell?<CR>")
K('n', ',tv', "<Cmd>let &virtualedit=(&ve=='all'?'block':'all')|set ve?<CR>")
K('n', ',tw', "<Cmd>setl wrap! wrap?<CR>")

-- Spell =========
-- o.spellfile = { MYCONF .. '/spell/en.utf-8.add' } -- One file of mixed content
o.spellfile = vim.fs.normalize('~/.config/nvim/spell/en.utf-8.add') -- One file of mixed content
o.spellcapcheck = ''  -- Don't auto-capitilize suggested words
-- if !filereadable(&spellfile . '.spl')| exe 'mkspell' &spellfile |en


K('n', '\\q', "<Cmd>copen<CR>")
K('n', '\\Q', "<Cmd>lopen<CR>")
-- K('n', '\\Q', "<Cmd>cclose<CR>")


-- K('n', '<F3>', [[
-- :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
-- \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
-- \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>
-- ]])
