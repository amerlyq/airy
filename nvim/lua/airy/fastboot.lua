--SRC: Speedup neovim - rok ⌇⡢⡳⣠⢗ https://aca.github.io/neovim_startuptime.html
local o, g = vim.opt, vim.g

--DEBUG: turn on printing messages during file operations and from autocmd
--SRC: autocmd - FileType autocommand not working in Neovim - Vi and Vim Stack Exchange ⌇⡢⡲⣓⠎
--   https://vi.stackexchange.com/questions/22637/filetype-autocommand-not-working-in-neovim
o.shortmess:remove {'F'} -- DFL=filnxtToOF


--PERF: reduce ENOENT checks
--FAIL: all plugins dirs are hiddenly added to &rtp -- so many ENOENT anyway
--  TODO:DEBUG: $ strace
-- + /@/airy/nvim
-- ! /etc/xdg/nvim  | SRC(nvim):FAIL: ~hardcoded during compiling, can't skip
-- ~ /t/nvim/site
-- - /usr/local/share/nvim/site
-- - /usr/share/nvim/site
-- + /usr/share/nvim/runtime
-- ~ /usr/share/nvim/runtime/pack/dist/opt/matchit
-- - /usr/lib/nvim
-- - /usr/share/nvim/site/after
-- - /usr/local/share/nvim/site/after
-- - /t/nvim/site/after
-- - /etc/xdg/nvim/after
-- + /@/airy/nvim/after
-- ? /usr/share/vim/vimfiles

-- OR: vim.env.MYVIMRC.parent
o.runtimepath = { MYCONF, vim.env.VIMRUNTIME }  -- '/@/airy/nvim/after'
o.packpath = { MYCONF, MYPLUG .. '/preload' }
-- o.packpath = MYPLUG .. '/lazy'
-- o.packpath = ''
-- NEED:(python,nou): vim.cmd('source ' .. vim.env.VIMRUNTIME .. '/plugin/rplugin.vim')
o.loadplugins = false


--FAIL: waiting the «jump to the last position» is VERY irritating
--   (here) o.shadafile = 'NONE'
--   (lazy-load) vim.cmd [[ set shadafile= | rshada | silent! normal! g`"zvzz ]]
--WARN: marks (last position) is only written to ShaDa on vim exit
--  MAYBE: use "au BufWipeout :wshada" to store them
--PERF: reduce .shada file size to ~115kB (5ms) .vs. DFL=660kB (~36ms)
--  HACK:(edit): source $VIMRUNTIME/plugin/shada.vim | edit /@/xdg_share/nvim/shada/main.shada
o.shada = { "'30", "<0", "s1", "h", "rterm://" }
o.history = 999


g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.python3_host_prog = '/usr/bin/python3'


-- SRC: Introducing filetype.lua and a call for help : neovim ⌇⡢⡱⡦⣳
--   https://www.reddit.com/r/neovim/comments/rvwsl3/introducing_filetypelua_and_a_call_for_help/
g.do_filetype_lua = 1
g.did_load_filetypes = 0


--DISABLED:BET:USE: 'o.loadplugins = false'
--ALT: copy-paste and edit /usr/share/nvim and export new $VIMRUNTIME
--  NICE: won't load all those unnecessary files/plugins at all
-- g.loaded_tutor_mode_plugin = 0
-- g.loaded_2html_plugin = 0
-- g.loaded_netrwPlugin = 0
-- g.loaded_tarPlugin = 0
-- g.loaded_zipPlugin = 0
-- g.loaded_gzip = 0
-- g.loaded_shada_plugin = 0  -- DISABLED: register FileType *.shada


--ALSO:CHECK:
-- let g:loaded_matchparen        = 0
-- let g:loaded_matchit           = 0
-- let g:loaded_logiPat           = 0
-- let g:loaded_rrhelper          = 0
-- let g:loaded_man               = 0
-- let g:loaded_spellfile_plugin  = 0
-- let g:loaded_netrw             = 0
-- let g:loaded_remote_plugins    = 0


--PERF: redraw
-- set nonumber
-- set norelativenumber
-- set nocursorcolumn
-- set nocursorline
-- set synmaxcol=200
-- set lazyredraw
