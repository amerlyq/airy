local K = require 'keys.K'

K('n', ',/', function()
  local s = "\\V" .. vim.fn.getreg("+")
  vim.fn.histadd("/", s, "c")
  vim.fn.setreg("/", s, "c")
end)
