-- vim:ts=2:sts=2:sw=2:et
local o, g = vim.opt, vim.g

--DEBUG: turn on printing messages during file operations and from autocmd
--SRC: autocmd - FileType autocommand not working in Neovim - Vi and Vim Stack Exchange ⌇⡢⡲⣓⠎
--   https://vi.stackexchange.com/questions/22637/filetype-autocommand-not-working-in-neovim
o.shortmess:remove {'F'} -- DFL=filnxtToOF

require 'airy.fastboot'
require 'airy.options'
require 'airy.colors'

require 'airy.statusline'

require 'keys.lead'
require 'keys.escape'
require 'keys.move'
require 'keys.edit'
require 'keys.select'
require 'keys.plugins'

require 'lazy.init'
