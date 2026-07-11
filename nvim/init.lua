-- vim:ts=2:sts=2:sw=2:et
-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

-- OFF: https://github.com/neovim/neovim/wiki/FAQ#why-lua-51-instead-of-lua-53
-- ONLY: /usr/share/luajit-2.1.0-beta3/?.lua -- plenary/profile
package.path = './?.lua'
package.cpath = './?.so'


-- USAGE: vim.env.MYLUA
-- vim.cmd [[ let $MYLUA = fnamemodify($MYVIMRC, ':h') . '/lua/' ]]
MYCONF = '/d/airy/nvim'
MYPLUG = '/d/plugins/nvim'


--DISABLED:BAD:PERF: with deferred plugins it becomes slower, not faster (48ms vs 61ms)
-- SRC: https://github.com/neovim/neovim/pull/22668
-- OLD:ALT: https://github.com/lewis6991/impatient.nvim
-- (native): adds the Lua loader using the byte-compilation cache
-- FIXED:ERR: Error executing vim.schedule lua callback: /@/airy/nvim/lua/plug/cmp.lua:4: module 'cmp' not found:
-- vim.opt.packpath = { MYPLUG .. '/preload', MYPLUG .. '/lazy', MYCONF }
-- if vim.loader then
--   vim.loader.enable()
-- end


-- DEBUG: what files ':runtime' found
-- vim.opt.verbose = 2
-- lua print(package.path)

require 'airy.fastboot'

require 'airy.options'
require 'airy.colors'
require 'airy.autocmds'

require 'keys.lead'
require 'keys.escape'

require 'keys.edit'
require 'keys.integ'
require 'keys.move'
require 'keys.remap'
require 'keys.replace'
require 'keys.shell'
require 'keys.utils'
require 'keys.visual'
require 'keys.yank'

require 'airy.diagnostics'
require 'keys.plugins'

-- plugins with pure "vim.g" configs (w/o require())
require 'preload.rainbow'
-- require 'preload.neotest'
-- require 'preload.debugger'


-- local status, basilisk = pcall(require, "basilisk")
-- -- if status then
--   basilisk.setup({})
--   -- This registers the internal FileType hook long before any buffer opens
--   vim.lsp.enable("basilisk")
-- -- end


require 'lazyload'
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


-- FIXED? neovim don't open or diff (nvim -d) files if filesize is >100k
--   BET: disable all features
--   OLD: https://github.com/LunarVim/bigfile.nvim
--   TRY: https://github.com/pteroctopus/faster.nvim
-- local max_filesize = 100 * 1024 -- 100 KB
-- vim.api.nvim_create_autocmd({ "BufReadPre" }, {
--   pattern = "*",
--   callback = function(ev)
--     -- Check if the target is a valid, existing file
--     local file = ev.match
--     local stats = vim.uv.fs_stat(file)
--
--     if stats and stats.size > max_filesize then
--       -- Print a warning in the terminal layout
--       vim.schedule(function()
--         vim.notify("File too large (>100KB). Aborting open.", vim.log.levels.WARN)
--         -- Delete the buffer completely to avoid opening it
--         vim.cmd("bd!")
--       end)
--     end
--   end,
-- })
