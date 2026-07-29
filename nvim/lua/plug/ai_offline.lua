
-- 1. Fast check if Ollama port is open (127.0.0.1:11434)
local function ollama_is_running()
  local uv = vim.uv or vim.loop
  local client = uv.new_tcp()
  local is_open = false

  client:connect("127.0.0.1", 11434, function(err)
    if not err then is_open = true end
    client:close()
  end)

  -- Wait max 50ms for local loopback connection
  vim.wait(20, function() return is_open end, 10, false)
  return is_open
end

-- ALT: Only initialize if you launch Neovim as: OLLAMA=1 nvim
-- if vim.env.OLLAMA != "1" then return end
if not ollama_is_running() then return end


require 'plug.ai_codecompanion_cfg'
require 'plug.ai_minuet_cfg'
