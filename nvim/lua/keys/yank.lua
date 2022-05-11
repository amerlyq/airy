local K = require'keys.bind'.K

K('n', ',/', function()
  local s = "\\V" .. vim.fn.getreg('+')
  vim.fn.histadd("/", s)
  vim.fn.setreg("/", s, "c")
  vim.cmd('noau normal! n')
end)
