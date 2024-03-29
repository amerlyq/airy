local autocmd = vim.api.nvim_create_autocmd


autocmd('FileType', {
  desc = "(Aux) filetype settings",
  pattern = 'lua',
  command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab'
})


-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank { higroup = "TextYank", timeout = 130 } end,
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
})


--FIXME: don't jump after moving between buffers
--FIXME:FAIL:(once=true): only restore position on first opening
--ALT: https://github.com/vladdoster/remember.nvim
--WARN: ShaDa should be loaded on startup for this to work
autocmd('BufReadPost', {
  desc = "(State) restore cursor position",
  command = 'silent! normal! g`"zvzz'
})


--SRC: https://github.com/cappyzawa/trim.nvim
--BET:(only modified lines): https://github.com/axelf4/vim-strip-trailing-whitespace
--   https://www.reddit.com/r/neovim/comments/em9ta9/vimstriptrailingwhitespace_now_supports_neovim/
--ALSO: https://github.com/ntpeters/vim-better-whitespace
--HACK:USAGE: save w/o formatting ":noa w" or ":set eventignore=BufWritePre | w | set eventignore="
--ALSO:
--   %s/\s\+$//e           -- remove unwanted spaces
--   %s/\($\n\s*\)\+\%$//  -- trim last line (OR: s/\\v%($\\_s*)+%$//) FAIL: uses RAM > maxmempattern
--   %s/\%^\n\+//          -- trim first line
--   %s/\(\n\n\)\n\+/\1/   -- replace multiple blank lines with a single line
autocmd("BufWritePre", {
  desc = "(Save) strip trailing spaces and empty lines",
  callback = function()
    local save = vim.fn.winsaveview()
    --BAD:(keeppatterns): prevents us using shortcut :g/xxx/s///e
    --TEMP: remove shit from MSTeams copy-paste
    vim.api.nvim_exec('keepjumps keeppatterns silent g/[\\r\\u200b]/s/[\\r\\u200b]//e', false)
    vim.api.nvim_exec('keepjumps keeppatterns silent g/\\s\\+$/s/\\s\\+$//e', false)
    vim.api.nvim_exec('keepjumps keeppatterns silent! /\\v^%(\\_s*\\S)@!/,$d_', false)
    --ALSO: let &fixeol=g:strip_lines
    vim.fn.winrestview(save)
  end
})


--DISABLED: use "which-key" which overrules this
--HACK: Infinite wait on mappings, but timeout on keycodes (like <\e..>)
--WARN: you must eliminate clushing keymaps like ',x' and ',xy'
-- local K = require'keys.bind'.K
-- local o, g = vim.opt, vim.g
-- o.timeout =
-- set timeoutlen=1000 ttimeoutlen=32
-- set notimeout ttimeout
-- " Leave insert mode quickly
-- augroup FastEscape
--   autocmd!
--   au InsertEnter * set timeoutlen=0 ttimeoutlen=0
--   au InsertLeave * set timeoutlen=1000 ttimeoutlen=32
-- augroup END
