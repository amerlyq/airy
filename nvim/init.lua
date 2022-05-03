-- vim:ts=2:sts=2:sw=2:et
local o, g = vim.opt, vim.g

require 'airy.fastboot'
require 'airy.statusline'

o.termguicolors = true
-- [_] NICE:TRY: rewrite to Lua batch-API -- *api-highlights* nvim_buf_add_highlight()
vim.cmd 'colorscheme airy'            -- PERF=2ms
-- vim.g.material_style = "deep ocean"
-- vim.cmd 'colorscheme material'     -- PERF=8ms
-- vim.cmd 'colorscheme soluarized'   -- PERF=12ms
-- vim.cmd [[colorscheme solarized]]  -- PERF=19ms


-- ALT: nvim/after/ftplugin/python.lua
vim.api.nvim_create_autocmd('FileType', {
  desc = "(lazy) LSP and TreeSitter",
  pattern = 'python',  -- vim.bo.filetype
  nested = true,
  callback = function()
    require'pure.lsp'
    vim.cmd [[packadd! nvim-treesitter]]
  end
})
