local M = {}

-- Initialize default state immediately so other files can safely read it
M.has = {
  ollama = false,
  codecompanion = false,
  minuet = false,
}

-- Fast, completely non-blocking async port check
function M.check_ollama_port(callback)
  local uv = vim.uv or vim.loop
  local client = uv.new_tcp()
  if not client then return false end

  local is_open = false
  client:connect("127.0.0.1", 11434, function(err)
    if not err then is_open = true end
    client:close()
    -- ALT: Schedule back to Neovim's main thread safely
    -- vim.schedule(function()
    --   callback(is_open)
    -- end)
  end)
  -- Wait max 20ms for local loopback connection
  vim.wait(20, function() return is_open end, 5, false)
  return is_open
end

-- -- ALT: Async run the check silently in the background right now
-- M.check_ollama(function(is_running)
--   M.has.ollama = is_running
--   if is_running then
--     -- Safely load plugins only if Ollama responds
--     pcall(require, 'plug.ai_codecompanion_cfg')
--     M.has.codecompanion = true
--     pcall(require, 'plug.ai_minuet_cfg')
--     M.has.minuet = true
--     -- Optional: trigger an event so your statusline or UI updates dynamically
--     vim.api.nvim_exec_autocmds("User", { pattern = "OllamaReady" })
--   end
-- end)


-- ALT: vim.g.ollama_is_running = ...
M.has.ollama = M.check_ollama_port()

-- ALT: Only initialize if you launch Neovim as: OLLAMA=1 nvim
-- if vim.env.OLLAMA != "1" then return end

-- 3. Graceful fallback instead of 'return' early-exit.
-- This ensures the table structure remains intact for blink.cmp or other configurations.
if M.has.ollama then
  -- No pcall used here. If your config files have errors, Neovim will crash
  -- cleanly and print the exact line number causing the problem.
  require('plug.ai_codecompanion_cfg')
  M.has.codecompanion = true

  require('plug.ai_minuet_cfg')
  M.has.minuet = true
end

return M
