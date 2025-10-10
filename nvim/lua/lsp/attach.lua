-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)

  -- local util = require('lspconfig.util')
  -- -- `pylsp-mypy` requires a specific override
  -- -- Only configure pylsp-mypy if root_dir is available
  -- -- local root_dir = vim.lsp.buf.root_dir()
  -- local root_dir = util.find_git_ancestor(vim.fn.expand('%:p')) or vim.loop.cwd()
  -- if root_dir then
  --   -- local venv_executable = root_dir .. "/.venv/bin/python"
  --   local venv_executable = util.path.join(root_dir, '.venv/bin/python')
  --   if vim.fn.filereadable(venv_executable) then
  --     client.config.settings.pylsp.plugins.pylsp_mypy = {
  --       enabled = true,
  --       overrides = {
  --         "--python-executable",
  --         venv_executable,
  --         -- true,
  --       },
  --     }
  --   end
  -- end

  require('lsp.keys')(client, bufnr)

  -- Enable completion triggered by <c-x><c-o>
  -- OR: :autocmd Filetype python setlocal omnifunc=v:lua.vim.lsp.omnifunc
  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Format on save -- and restore highlights
  -- vim.cmd [[autocmd BufWritePre <buffer> exe 'lua vim.lsp.buf.formatting_sync()'|Semshi highlight]]
  -- WTF: it's registered for all .py buffers BUT formatting works only for first buffer
  -- vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]

  -- FIXED:(clear=false): allow duplicates for multiple buffers
  local group = vim.api.nvim_create_augroup('MyLsp', { clear = false })

  local function autocmd(evs, cb, s)
    vim.api.nvim_create_autocmd(evs, {
      buffer = bufnr,
      group = group,
      callback = cb,
      desc = s,
    })
  end

  local B = vim.lsp.buf
  autocmd('BufWritePre', function() B.format { async = false } end, "Auto Format")
  -- ALT: vim-illuminate
  autocmd({ 'CursorHold', 'CursorHoldI' }, B.document_highlight, "hi! show under cursor")
  autocmd('CursorMoved', B.clear_references, "hi! clear under cursor")
end

return on_attach


-- vim.api.nvim_create_autocmd('LspAttach', {
--   group = vim.api.nvim_create_augroup('my.lsp', {}),
--   callback = function(args)
--     local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
--     if client:supports_method('textDocument/implementation') then
--       -- Create a keymap for vim.lsp.buf.implementation ...
--     end
--     -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
--     if client:supports_method('textDocument/completion') then
--       -- Optional: trigger autocompletion on EVERY keypress. May be slow!
--       -- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
--       -- client.server_capabilities.completionProvider.triggerCharacters = chars
--       vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
--     end
--     -- Auto-format ("lint") on save.
--     -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
--     if not client:supports_method('textDocument/willSaveWaitUntil')
--         and client:supports_method('textDocument/formatting') then
--       vim.api.nvim_create_autocmd('BufWritePre', {
--         group = vim.api.nvim_create_augroup('my.lsp', {clear=false}),
--         buffer = args.buf,
--         callback = function()
--           vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
--         end,
--       })
--     end
--   end,
-- })
