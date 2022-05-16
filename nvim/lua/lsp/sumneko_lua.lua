-- BUG: not deleted tmp dirs: /tmp/lua-language-server.2dyu
--   SRC: /usr/lib/lua-language-server/main.lua
--     LOGPATH  = LOGPATH  and util.expandPath(LOGPATH)  or (ROOT:string() .. '/log')
-- BUG: workspace set to /@/airy and scans/loads ALL files recursively for .lua

-- Memory leaks when idle · Issue #1117 · sumneko/lua-language-server ⌇⡢⡻⣏⢞
--   https://github.com/sumneko/lua-language-server/issues/1117


-- Make runtime files discoverable to the server
-- FIXME: only use /@/airy/nvim/lua/ location
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')
-- table.insert(runtime_path, '/usr/share/luajit-2.1.0-beta3/?.lua')



-- VIZ: settings
-- https://github.com/sumneko/lua-language-server/blob/master/locale/en-us/setting.lua


--DEP: $ paci lua-language-server
local settings = {
  Lua = { -- sumneko_lua
    runtime = {
      -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
      version = 'LuaJIT',
      -- OPT: Setup your lua path
      -- path = runtime_path,
      -- pathStrict = 'true',
    },
    diagnostics = {
      -- Get the language server to recognize the `vim` global
      globals = { 'vim', 'require' },
      -- Disable scanning whole workspace in the background
      workspaceDelay = -1,
    },
    workspace = {
      -- Make the server aware of Neovim runtime files
      -- library = vim.api.nvim_get_runtime_file('', true),
      library = {
        [vim.fn.expand('$VIMRUNTIME/lua')] = true,
        [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        [vim.fn.stdpath('config') .. '/lua'] = true,
      }
    },
    -- Do not send telemetry data containing a randomized but unique identifier
    telemetry = {
      enable = false,
    },
  },
}

return settings
