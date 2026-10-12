-- REF: https://luals.github.io/
-- ~/.config/nvim/lsp/lua_ls.lua
return {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT", -- Instructs the engine that Neovim executes via LuaJIT
      },
      diagnostics = {
        globals = { "vim" }, -- Extinguishes the 'Undefined global vim' warning
        -- disable = {"lowercase-global" },
      },
      completion = {
        callSnippet = "Replace",
      },
      -- workspace = {
      --   -- Make the server aware of Neovim runtime files and plugins
      --   library = { vim.env.VIMRUNTIME },
      --   checkThirdParty = false,
      -- },
      telemetry = { enable = false },
    },
  },
}

-- ALSO
-- https://github.com/ofseed/mpv/tree/main/types
-- https://github.com/Yukari0201/mpv-lua-stubs


-- ALSO: yazi-lsp.nvim OR:
-- lspconfig.lua_ls.setup({
--   on_init = function(client)
--     -- Check if you are working inside a yazi config or plugin directory
--     local path = client.workspace_folders[1].name
--     if path:match("yazi") then
--       client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
--         runtime = { version = 'LuaJIT' },
--         diagnostics = {
--           globals = { "ya", "cx", "ui", "Header", "Parent", "Current", "Preview", "Status", "Manager" },
--         },
--       })
--       client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
--     end
--     return true
--   end
-- })
