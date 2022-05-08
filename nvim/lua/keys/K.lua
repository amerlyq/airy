
-- WAIT:(merge): for "desc" param ⌇⡢⡮⢰⢋
--  https://github.com/folke/which-key.nvim/issues/242
local KG = vim.api.nvim_set_keymap  -- OR: local KS = vim.keymap.set
-- local KB = vim.api.nvim_buf_set_keymap(bufnr=0, m, lhs, rhs, opts)

-- ALT: https://github.com/folke/which-key.nvim/issues/267
function noremap(modes, lhs, rhs, desc)
  local opts = { noremap = true }
  if type(rhs) == "function" then
    opts.callback = rhs
    rhs = ''
  end
  for i = 1, #modes do
    KG(modes:sub(i,i), lhs, rhs, opts)
  end
end


function KE(modes, lhs, rhs, desc)
  local opts = { noremap = true, expr = true }
  if type(rhs) == "function" then
    opts.callback = rhs
    rhs = ''
  end
  for i = 1, #modes do
    KG(modes:sub(i,i), lhs, rhs, opts)
  end
end


-- local K = noremap
return noremap
