-- SRC: https://github.com/olimorris/codecompanion.nvim
--   * Uses dynamic variables like @files, @buffers, @lsp (to pull AST
--     diagnostic/type graphs), and @git to pass precise, bounded codebase
--     context into your local LLM.
-- Fits well alongside local vector search or local MCP servers.

-- NEED:
-- $ sudo pacman -S ollama-cuda
-- $ sudo systemctl enable --now ollama
-- $ ollama pull qwen2.5-coder:14b

-- DEBUG:
-- $ journalctl -fu ollama
-- $ curl http://localhost:11434/api/tags
-- $ pgrep -l llama
-- $ ollama list
-- $ ollama ps

local ok, codecompanion = pcall(require, "codecompanion")
if not ok then return end

codecompanion.setup({
  strategies = {
    chat = { adapter = "ollama" },
    inline = { adapter = "ollama" },
  },
  adapters = {
    http = {
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          schema = {
            model = { default = "qwen2.5-coder:14b" },
          },
        })
      end,
    },
  },
})

-- Register keymaps only when loaded
local map = vim.keymap.set
map({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
map({ "n", "v" }, "<leader>ci", "<cmd>CodeCompanion<cr>", { desc = "AI Inline Prompt" })
map({ "n", "v" }, "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions" })
map("v", "<leader>ce", ":CodeCompanion /fix<cr>", { desc = "AI Fix Selected Code" })
