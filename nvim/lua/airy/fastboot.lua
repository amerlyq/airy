local o, g = vim.opt, vim.g

--PERF: reduce ENOENT checks
--FAIL: all plugins dirs are hiddenly added to &rtp -- so many ENOENT anyway
--  TODO:DEBUG: $ strace
-- + /@/airy/nvim
-- - /etc/xdg/nvim
-- ~ /t/nvim/site
-- - /usr/local/share/nvim/site
-- - /usr/share/nvim/site
-- + /usr/share/nvim/runtime
-- * /usr/share/nvim/runtime/pack/dist/opt/matchit
-- - /usr/lib/nvim
-- - /usr/share/nvim/site/after
-- - /usr/local/share/nvim/site/after
-- - /t/nvim/site/after
-- - /etc/xdg/nvim/after
-- + /@/airy/nvim/after
-- ? /usr/share/vim/vimfiles
o.runtimepath = { '/@/airy/nvim', '/usr/share/nvim/runtime', '/@/airy/nvim/after' }


g.loaded_tutor_mode_plugin = 0
g.loaded_2html_plugin = 0
g.loaded_netrwPlugin = 0
g.loaded_tarPlugin = 0
g.loaded_zipPlugin = 0
g.loaded_gzip = 0

g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.python3_host_prog = '/usr/bin/python3'


-- SRC: Introducing filetype.lua and a call for help : neovim ⌇⡢⡱⡦⣳
--   https://www.reddit.com/r/neovim/comments/rvwsl3/introducing_filetypelua_and_a_call_for_help/
g.do_filetype_lua = 1
g.did_load_filetypes = 0
