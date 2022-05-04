-- vim:ts=2:sts=2:sw=2:et
local o, g = vim.opt, vim.g

--DEBUG: turn on printing messages during file operations and from autocmd
--SRC: autocmd - FileType autocommand not working in Neovim - Vi and Vim Stack Exchange ⌇⡢⡲⣓⠎
--   https://vi.stackexchange.com/questions/22637/filetype-autocommand-not-working-in-neovim
o.shortmess:remove {'F'} -- DFL=filnxtToOF

vim.opt.whichwrap:remove({ 'b', 's' })

require 'airy.fastboot'
require 'airy.statusline'

o.termguicolors = true
-- [_] NICE:TRY: rewrite to Lua batch-API -- *api-highlights* nvim_buf_add_highlight()
vim.cmd 'colorscheme airy'            -- PERF=2ms
-- vim.g.material_style = "deep ocean"
-- vim.cmd 'colorscheme material'     -- PERF=8ms
-- vim.cmd 'colorscheme soluarized'   -- PERF=12ms
-- vim.cmd [[colorscheme solarized]]  -- PERF=19ms


vim.api.nvim_create_autocmd('FileType', {
  desc = "(Lazy) packadd LSP and TreeSitter",
  once = true,
  pattern = 'python',
  callback = function()
    require 'lazy.lsp'

    -- FAIL: cmds not loaded when directly opening .py file
    -- vim.cmd [[packadd! nvim-treesitter]]
    -- -- require("nvim-treesitter.configs").reattach_module(mod)
    -- -- vim.cmd [[ setlocal indentexpr=nvim_treesitter#indent() ]]
    -- if vim.fn.has('vim_starting') == 0 then
    --   vim.cmd [[packadd nvim-treesitter]]
    -- end
  end
})
