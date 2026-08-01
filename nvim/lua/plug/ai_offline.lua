local M = {}

-- ALT: Only initialize if you launch Neovim as: OLLAMA=1 nvim
-- if vim.env.OLLAMA != "1" then return end

-- ALT: vim.g.ollama_is_running = ...
M.ollama_reachable = nil  -- unknown until the async check resolves

function M.refresh_ollama_status()
  local uv = vim.uv or vim.loop
  local client = uv.new_tcp()
  if not client then
    M.ollama_reachable = false
    return
  end

  local done = false

  local function finish(result)
    if done then return end
    done = true
    M.ollama_reachable = result
    if not client:is_closing() then client:close() end
    -- ALT: Schedule back to Neovim's main thread safely
    -- vim.schedule(function()
    --   callback(is_open)
    -- end)
    -- -- MAYBE: trigger an event so your statusline or UI updates dynamically
    -- vim.api.nvim_exec_autocmds("User", { pattern = "OllamaReady" })
  end

  local ok = client:connect('127.0.0.1', 11434, function(err)
    if err then
      finish(false)
      return
    end
    -- TCP connected — could be ssh forward with dead backend, so verify HTTP
    client:read_start(function(read_err, chunk)
      if done then return end
      if read_err or not chunk then
        finish(false)  -- closed/reset with no response = dead backend
      elseif chunk:match('^HTTP/') then
        finish(true)
      else
        finish(false)
      end
    end)
    client:write('GET / HTTP/1.0\r\nHost: localhost\r\n\r\n')
  end)

  if not ok then
    finish(false)
    return
  end

  -- ALT: wait max 20ms for local loopback connection
  -- vim.wait(20, function() return done end, 5, false)

  -- safety timeout in case nothing ever calls back
  local timer = uv.new_timer()
  timer:start(300, 0, function()
    timer:stop()
    timer:close()
    finish(false)
  end)
end

M.refresh_ollama_status()  -- fire once at startup, async

-- ALT: skip whole plugin
-- if M.ollama_reachable then
--   M.has.minuet = require('plug.ai_minuet_cfg')
-- end

-- No pcall used here. If your config files have errors, Neovim will crash
-- cleanly and print the exact line number causing the problem.
M.has = {
  codecompanion = require('plug.ai_codecompanion_cfg'),
  minuet = require('plug.ai_minuet_cfg'),
}

return M
