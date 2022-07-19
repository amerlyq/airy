local K = require 'keys.bind'.K
local bw = "b"

-- ALSO: https://gist.github.com/habamax/0a6c1d2013ea68adcf2a52024468752e
-- SEE: https://github.com/nanotee/dotfiles/tree/master/.config/nvim
--   map[''].gx = {'...'}
-- if vim.fn.has("unix") == 1 then
K('n', 'gx', '<Cmd>call jobstart(["xdg-open", expand("<cfile>")], {"detach": v:true})<CR>')
-- K('x', 'gx', '<Cmd>call jobstart([bw, "--", GetVisualSelection(" ")], {"detach": v:true})<CR>')
-- K('x', 'gx', function() vim.fn.jobstart([bw, "--", getVisualSelection()], {detach=true})end)

vim.cmd [[
fun! OpenBrowser(url)
  let bw = "b"
  call jobstart([bw, "--", a:url], {"detach": v:true})
endf
]]

-- OFF:REF: https://github.com/luvit/luv/blob/master/docs.md
-- SRC(detach): https://github.com/luvit/luvit/blob/master/deps/childprocess.lua#L72
--   BAD: "vim.loop" is a too complex shit
--   ALSO: http://docs.libuv.org/en/v1.x/guide/processes.html
-- VIZ:DEBUG: :lua print(vim.inspect(vim.loop))
-- 🔁 Using LibUV in Neovim ⌇⡢⡻⢝⡁
--   TUT: https://teukka.tech/vimloop.html
--   https://github.com/neovim/neovim/issues/7607

K('x', 'gx', function()
  -- FAIL: vsel is always empty or wrong
  -- local vsel = require('seize.vsel')()
  vim.cmd('noau normal! "vy')
  local vsel = vim.fn.getreg('v')
  local handle, _pid = vim.loop.spawn(bw, {
    args = { "--", vsel },
    detached = true
  }, (function() print('DONE') end)) -- handle:close()
  vim.loop.unref(handle)
end)
