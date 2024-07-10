--%USAGE: local K = table.unpack(require'keys.bind')
--%USAGE: local K, KE = table.unpack(require'keys.bind')

-- WAIT:(merge): for "desc" param ⌇⡢⡮⢰⢋
--  https://github.com/folke/which-key.nvim/issues/242
local KG = vim.api.nvim_set_keymap  -- OR: local KS = vim.keymap.set
local KB = vim.api.nvim_buf_set_keymap

local function map(modes, lhs, rhs, desc, fn, opts)
  opts.desc = desc
  if type(rhs) == "function" then
    opts.callback = rhs
    rhs = ''
  end
  if modes == '' then
    fn(modes, lhs, rhs, opts)
  else
    for i = 1, #modes do
      fn(modes:sub(i,i), lhs, rhs, opts)
    end
  end
end

-- ALT: https://github.com/folke/which-key.nvim/issues/267
local function noremap(modes, lhs, rhs, desc)
  return map(modes, lhs, rhs, desc, KG, { noremap = true })
end


local function noremapexpr(modes, lhs, rhs, desc)
  return map(modes, lhs, rhs, desc, KG, { noremap = true, expr = true })
end


local function bufnoremap(bufnr, modes, lhs, rhs, desc)
  local KB_ = function(m,l,r,o) KB(bufnr, m,l,r,o) end
  return map(modes, lhs, rhs, desc, KB_, { noremap = true })
end

--FAIL: can't unpack keyvalue
--  SRC: https://stackoverflow.com/questions/60727950/lua-string-indexed-table-and-unpack
--%USAGE: local K, KE = require'keys.bind'.K, require'keys.bind'.KE
return {K=noremap, KE=noremapexpr}  -- , KB=bufnoremap, KG=KG, KM=map}

--%USAGE: local K = table.unpack(require'keys.bind')
--%USAGE: local K, KE = table.unpack(require'keys.bind')
--return {noremap, noremapexpr}
