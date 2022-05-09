-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

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

require 'keys.edit'
require 'keys.move'
require 'keys.replace'
require 'keys.visual'
require 'keys.yank'

require 'airy.diagnostics'
require 'keys.plugins'

require 'lazy'
require 'plug.rnvimr'

require 'airy.statusline'
-- require 'airy.notches'

-- require 'plugins.guides'
-- require 'plugins.telescope'
-- require 'plugins.treesitter'


-- TODO: ctags incremental re-generation
-- https://github.com/ludovicchabant/vim-gutentags
-- vim.g.gutentags_dont_load = true

-- require("trouble").setup {
--   icons=false,  -- NEED:DEP=nvim-web-devicons
--   -- auto_open = true,
--   auto_close = true,
--   -- auto_fold = true,
--   use_diagnostic_signs = true,
-- }

-- require("refactoring").setup({})
