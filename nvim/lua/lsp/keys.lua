local KB = vim.api.nvim_buf_set_keymap
local B = vim.lsp.buf


-- REF: `:help vim.lsp.*` for documentation on any of the below functions
local function lsp_mappings(client, bufnr)
  local KBn = function(lhs, fn, s) KB(bufnr, 'n', lhs, '', { callback = fn, noremap = true, desc = s }) end

  KBn('gd', B.definition, "definition [LSP]")
  KBn('gD', B.type_definition, "type_def [LSP]") -- DFL=,D | <LL>d
  -- KBn('gD', B.declaration) -- NOT
  KBn('gw', B.references, "references [LSP]") -- DFL=gr  @me=<LocalLeader>u
  -- KBn('gW', B.incoming_calls) -- NOT
  -- KBn('gW', B.outgoing_calls) -- NOT
  -- KBn('<LocalLeader>g', B.implementation) -- DFL=gi NOT

  KBn('<F1>', B.hover, "hover [LSP]") -- DFL=K | <LL>K
  -- KBn('<C-k>', B.signature_help)

  -- KBn('<leader>wa', B.add_workspace_folder)
  -- KBn('<leader>wr', B.remove_workspace_folder)
  -- KBn('<leader>wl', function()
  --   vim.inspect(B.list_workspace_folders())
  -- end)

  KBn(',rn', B.rename, "Rename all under cursor [LSP]") -- ALT=<LocalLeader>R
  KBn(',ra', B.code_action, "code_action [LSP]") -- DFL= <leader>ca
  KBn('\\cg', function()
    vim.api.nvim_set_current_dir(client.config.root_dir)
  end, "Go to .git pj root") -- ALT: vim-rooter

  -- vim.api.nvim_buf_set_keymap(bufnr, '<LocalLeader>F', '<cmd>lua B.formatting()<CR>')
  KBn(',F', B.formatting, "formatting [LSP]")
  vim.api.nvim_create_user_command("Format", B.formatting, {})

  -- nnoremap <silent> g0    <cmd>lua B.document_symbol()<CR>
  KBn('gW', B.workspace_symbol, "workspace_symbol [LSP]")
end

return lsp_mappings
