-- vim:ts=2:sts=2:sw=2:et
local o, g = vim.opt, vim.g

require 'airy.fastboot'

require 'airy.options'
require 'airy.colors'
require 'airy.autocmds'

require 'airy.statusline'

require 'keys.lead'
require 'keys.escape'
require 'keys.move'
require 'keys.edit'
require 'keys.select'
require 'keys.plugins'

require 'lazy.init'

--PERF: search
o.grepprg = "rg --vimgrep --smart-case --sortr path --no-follow --hidden --glob '!.git'"

