local K = require'keys.bind'.K

K('n', ',/', function()
  local s = "\\V" .. vim.fn.getreg('+')
  vim.fn.histadd("/", s)
  vim.fn.setreg("/", s, "c")
  vim.cmd('noau normal! n')
end)

-- local function GetLineBookmark()
-- end
-- K('n', '<Leader>y', "<Cmd>lua GetLineBookmark(v:count, getline('.'))<CR>")
-- K('n', '<Leader>gy', "<Cmd>let &showtabline=(&stal<2?2:1)<CR>")
-- :xnoremap <CR> <Cmd>echom getregion(getpos('v'), getpos('.'), #{ type: mode() })<CR>

K('nv', '<Leader>y', "<Cmd>call setreg('+', getreg('%').':'.line('.'), 'l')<CR>")
K('n', '<Leader>Y', function()
  local path = vim.fn.getreg("%")
  if path:sub(1,1) ~= "/" then
    path = "//" .. path
  else
    -- TBD: if path -ef any_of(/d/*) then path = /d/xxx/ .. path:sub(...)
  end
  local lnum = vim.fn.line(".")
  local line = vim.fn.getline("."):gsub("^%s+", ""):gsub("%s+$", "")
  local bmrk = path .. ":" .. lnum .. ":" .. "\n  " .. line
  vim.fn.setreg("+", bmrk, "l")
end)
