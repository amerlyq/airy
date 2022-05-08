-- vim:ts=2:sts=2:sw=2:et
vim.cmd [[ let $MYLUA = fnamemodify($MYVIMRC, ':h') . '/lua/' ]]

require 'airy.fastboot'

require 'airy.options'
require 'airy.colors'
require 'airy.autocmds'

require 'keys.lead'
require 'keys.escape'
require 'keys.move'
require 'keys.edit'
require 'keys.visual'
require 'keys.yank'

require 'keys.plugins'

require 'lazy'
require 'lazy.rnvimr'

require 'airy.statusline'
