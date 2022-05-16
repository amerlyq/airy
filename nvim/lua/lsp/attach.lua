-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  require('lsp.keys')(client, bufnr)

  -- Enable completion triggered by <c-x><c-o>
  -- OR: :autocmd Filetype python setlocal omnifunc=v:lua.vim.lsp.omnifunc
  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Format on save -- and restore highlights
  -- vim.cmd [[autocmd BufWritePre <buffer> exe 'lua vim.lsp.buf.formatting_sync()'|Semshi highlight]]
  -- WTF: it's registered for all .py buffers BUT formatting works only for first buffer
  -- vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]

  local group = vim.api.nvim_create_augroup('MyLsp', { clear = true })

  local function autocmd(evs, cb, s)
    vim.api.nvim_create_autocmd(evs, {
      buffer = bufnr,
      group = group,
      callback = cb,
      desc = s,
    })
  end

  local B = vim.lsp.buf
  autocmd('BufWritePre', B.formatting_sync, "Auto Format")
  -- ALT: vim-illuminate
  autocmd({ 'CursorHold', 'CursorHoldI' }, B.document_highlight, "hi! show under cursor")
  autocmd('CursorMoved', B.clear_references, "hi! clear under cursor")
end

return on_attach
