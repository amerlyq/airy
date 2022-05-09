
local KB = vim.api.nvim_buf_set_keymap
local B = vim.lsp.buf


-- REF: `:help vim.lsp.*` for documentation on any of the below functions
local function lsp_mappings(_client, bufnr)
  local KBn = function(lhs, fn) KB(bufnr, 'n', lhs, '', { callback=fn, noremap=true }) end

  KBn('gD', B.declaration)
  KBn('gd', B.definition)
  KBn('gw', B.references) -- DFL=gr  @me=<LocalLeader>u

  KBn('<LocalLeader>K', B.hover)  -- DFL=K
  KBn('<LocalLeader>g', B.implementation)  -- DFL=gi
  -- KBn('<C-k>', B.signature_help)
  -- KBn('<leader>wa', B.add_workspace_folder)
  -- KBn('<leader>wr', B.remove_workspace_folder)
  -- KBn('<leader>wl', function()
  --   vim.inspect(B.list_workspace_folders())
  -- end)
  KBn('<LocalLeader>d', B.type_definition) -- DFL=,D
  KBn(',rn', B.rename) -- ALT=<LocalLeader>R
  -- KBn('<leader>ca', B.code_action)
  -- KBn('<Tab>s', require('telescope.builtin').lsp_document_symbols)

  -- vim.api.nvim_buf_set_keymap(bufnr, '<LocalLeader>F', '<cmd>lua B.formatting()<CR>')
  vim.api.nvim_create_user_command("Format", B.formatting, {})

  -- nnoremap <silent> g0    <cmd>lua B.document_symbol()<CR>
  -- nnoremap <silent> gW    <cmd>lua B.workspace_symbol()<CR>
end

return lsp_mappings
