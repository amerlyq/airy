local autocmd = vim.api.nvim_create_autocmd


autocmd('FileType', {
  desc = "(Aux) filetype settings",
  pattern = 'lua',
  command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab'
})


-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  group = highlight_group,
  callback = vim.highlight.on_yank
})


--FIXME:FAIL:(once=true): only restore position on first opening
--ALT: https://github.com/vladdoster/remember.nvim
autocmd('BufReadPost', {
  desc = "(State) restore cursor position",
  command = 'silent! normal! g`"zv'
})


--SRC: https://github.com/cappyzawa/trim.nvim
--BET:(only modified lines): https://github.com/axelf4/vim-strip-trailing-whitespace
--   https://www.reddit.com/r/neovim/comments/em9ta9/vimstriptrailingwhitespace_now_supports_neovim/
--ALSO: https://github.com/ntpeters/vim-better-whitespace
autocmd("BufWritePre", {
  desc = "(Save) strip trailing spaces and empty lines",
  callback = function()
    local save = vim.fn.winsaveview()
    --BAD:(keeppatterns): prevents us using shortcut :g/xxx/s///e
    vim.api.nvim_exec('keepjumps keeppatterns silent g/\\s\\+$/s/\\s\\+$//e', false)
    vim.fn.winrestview(save)
  end
})
