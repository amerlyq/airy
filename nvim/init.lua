-- vim:ts=2:sts=2:sw=2:et

-- USAGE: vim.env.MYLUA
-- vim.cmd [[ let $MYLUA = fnamemodify($MYVIMRC, ':h') . '/lua/' ]]
MYCONF = '/@/airy/nvim'
MYPLUG = '/@/plugins/nvim'

-- DEBUG: what files ':runtime' found
-- vim.opt.verbose = 2

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
require 'plug.rnvimr'

require 'airy.statusline'
