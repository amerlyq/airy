local o, g = vim.o, vim.g
local K = require 'keys.K'

g.rnvimr_enable_picker = 1
-- g.rnvimr_shadow_winblend = 50

g.rnvimr_layout = {
  relative = 'editor',
  width= 0.88 * o.columns,
  height= 0.88 * o.lines,
  col= 0.06 * o.columns + 2,
  row= 0.06 * o.lines,
  style= 'minimal'
}

--OR: g.rnvimr_enable_ex = 1
vim.api.nvim_create_autocmd('BufEnter', {
  desc = "(Hack) open !ranger for directories",
  command = "if isdirectory(expand('<amatch>'))| call rnvimr#enter_dir(expand('<amatch>'), expand('<abuf>')) |en"
})


K('n', ',f', ':RnvimrToggle<CR>')
K('n', '<M-o>', ':RnvimrToggle<CR>')
K('t', '<M-o>', '<C-\\><C-n>:RnvimrToggle<CR>')
K('t', '<M-i>', '<C-\\><C-n>:RnvimrResize<CR>')
-- K('n', '<S-Tab>', ':RnvimrToggle<CR>')
-- K('n', '<Tab>', ':RnvimrToggle<CR>')
-- K('n', '<C-Tab>', ':RnvimrResize<CR>')

--FAIL: preload in background can't load in hidden window
vim.defer_fn(function() vim.fn['rnvimr#init']() end, 1000)



-- diff --git i/autoload/rnvimr.vim w/autoload/rnvimr.vim
-- index 7af68c7..7c6a894 100644
-- --- i/autoload/rnvimr.vim
-- +++ w/autoload/rnvimr.vim
-- @@ -83,7 +83,8 @@ function! s:create_ranger(cmd, env) abort
--      call termopen(cmd, {'on_exit': function('s:on_exit')})
--      setfiletype rnvimr
--      call s:setup_winhl()
-- -    startinsert
-- +    " startinsert
-- +    call nvim_win_close(rnvimr#context#winid(), 0)
--  endfunction
--
--  function! s:defer_check_dir(path, bufnr) abort
-- diff --git i/ranger/plugins/urc.py w/ranger/plugins/urc.py
-- index b4a7418..1421391 100644
-- --- i/ranger/plugins/urc.py
-- +++ w/ranger/plugins/urc.py
-- @@ -96,6 +96,6 @@ class Urc():
--
--          ranger.args.confdir = confdir
--          custom_conf = self.fm.confpath('rc.conf')
-- -        self.fm.source(custom_conf)
--          self.load_commands()
--          self.load_plugins()
-- +        self.fm.source(custom_conf)
