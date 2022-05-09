-- Diagnostic keymaps for LSP
local K = require'keys.bind'.K

-- REF: `:h vim.diagnostic.*` for documentation on any of the below functions
local D = vim.diagnostic
K('n', '[d', D.goto_prev)
K('n', ']d', D.goto_next)
K('n', ',q', D.setloclist)
K('n', ',Q', D.setqflist)
K('n', ',tf', D.open_float)
K('n', ',tx', D.hide)
K('n', ',tX', D.disable)


vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = false,
})
