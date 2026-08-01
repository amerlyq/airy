-- SRC: https://github.com/olimorris/codecompanion.nvim
--   * Uses dynamic variables like @files, @buffers, @lsp (to pull AST
--     diagnostic/type graphs), and @git to pass precise, bounded codebase
--     context into your local LLM.
-- Fits well alongside local vector search or local MCP servers.

-- CFG: Env vars (put in shell rc or .env sourced before nvim launches):
-- export OPENROUTER_API_KEY="sk-or-v1-..."
-- export GEMINI_API_KEY="AIza..."

-- local ok, codecompanion = pcall(require, "codecompanion")
-- if not ok then return end

require("codecompanion").setup({
  -- opts = {
  --   log_level = "TRACE",  -- DEBUG may not capture full curl invocation; TRACE does
  -- },
  strategies = {
    chat = {
      -- adapter = "ollama",
      adapter = "openrouter",
      -- opts = {
      --   system_prompt = function(opts)
      --     return "python3.14+typehints, no boilerplate, no explanations, only correct code and comments"
      --     -- USAGE:(per tasks series): :lua vim.g.cc_system_prompt = "..."
      --     -- return vim.g.cc_system_prompt or "default terse python prompt"
      --   end,
      -- }
    },
    -- inline = { adapter = "ollama" },
    inline = { adapter = "openrouter" },
  },
  adapters = {
    http = {
      ollama = function()
        -- ALT: "openai_compatible" is a generic base adapter that defaults url to http://localhost:11434 (Ollama's default port)
        return require("codecompanion.adapters").extend("ollama", {
          -- name = "qwen_local",
          schema = {
            model = { default = "qwen2.5-coder:14b" },
            num_ctx = { default = 12288 },
            num_predict = { default = -1 },  -- -1 = unbounded, correct for chat/explanation
            -- num_predict = { default = 1024 },
            -- temperature = { default = 0.3 }, -- higher temp, more room for explanation/reasoning
          },
        })
      end,
      openrouter = function()
        return require("codecompanion.adapters").extend("openrouter", {
          env = {
            -- api_key = "OPENROUTER_API_KEY", -- reads from env var
            api_key = "cmd:pass fin/svc/openrouter.ai | awk '/apikey/{printf\"%s\",$2;exit}'",
            -- url = "https://openrouter.ai/api",
            -- chat_url = "/v1/chat/completions",
          },
          schema = {
            model = {
              default = "poolside/laguna-s-2.1:free",
              -- default = "qwen/qwen-2.5-coder-32b-instruct:free",
              -- swap for any :free-tagged model on openrouter.ai/models
              --   (fallback within openrouter if rate-limited:)
              -- "inclusionai/ling-3.0-flash:free"
            },
            -- extra_body = {
            --   -- OpenRouter's own routing/fallback on failure/rate-limit
            --   -- VIZ: https://openrouter.ai/models?max_price=0
            --   models = {
            --     "poolside/laguna-s-2.1:free",    -- (primary)
            --     "poolside/laguna-xs-2.1:free",   -- (faster, still beats North Mini Code)
            --     "nvidia/nemotron-3-super:free",  -- (untested claim, 1M context if you need it)
            --     "cohere/north-mini-code:free",   -- (weakest verified showing)
            --     -- Skip for coding:
            --     --   - Gemma 4 (26B A4B / 31B) — general multimodal, coding is incidental not a design target.
            --     --   - Nemotron 3 Nano Omni / Nano VL / Nano 9B V2 — multimodal/perception or general-purpose,
            --     --     not agentic-coding-focused.
            --     --   - Nemotron 3.5 Content Safety — a moderation/guardrail model, not usable for coding at all.
            --     --   - gpt-oss-20b — general-purpose OSS model, workable in a pinch but no coding specialization claimed.
            --   },
            --   route = "fallback",
            -- },
          },
          headers = {
            ["HTTP-Referer"] = "https://github.com/olimorris/codecompanion.nvim",
            ["X-Title"] = "codecompanion.nvim",
          },
        })
      end,
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          env = {
            api_key = "GEMINI_API_KEY",
          },
          schema = {
            model = { default = "gemini-2.0-flash-exp" },
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

-- :CodeCompanionChat Adapter ollama
-- :CodeCompanionChat Adapter openrouter
-- :CodeCompanionChat Adapter gemini
-- vim.keymap.set("n", "<leader>ao", function() require("codecompanion").adapters.set("openrouter") end, { desc = "CC: OpenRouter" })
-- vim.keymap.set("n", "<leader>al", function() require("codecompanion").adapters.set("ollama") end, { desc = "CC: Ollama (local)" })
-- vim.keymap.set("n", "<leader>ag", function() require("codecompanion").adapters.set("gemini") end, { desc = "CC: Gemini" })


-- Override SYSTEM prompt
--   interactions = {
--     chat = {
--       adapter = "qwen_local",
--       opts = {
--         -- dynamic: swap task-series prompt via vim.g.cc_system_prompt
--         system_prompt = function(ctx)
--           return vim.g.cc_system_prompt or [[
-- python3.14+typehints, no boilerplate, no explanations, only correct code and comments
-- ]]
--         end,
--       },
--     },
--     inline = {
--       adapter = "qwen_local",
--     },
--   },
--
--   -- optional: predefine task-series prompts you can switch between
--   prompt_library = {
--     ["Set: Refactor mode"] = {
--       strategy = "chat",
--       description = "Switch system prompt to refactor-focused",
--       opts = { index = 1 },
--       prompts = {
--         {
--           role = "system",
--           content = function()
--             vim.g.cc_system_prompt = "You refactor Python for minimal diffs, preserving behavior exactly. Explain nothing unless asked."
--             return "Refactor mode set."
--           end,
--         },
--       },
--     },
--     ["Set: Explain mode"] = {
--       strategy = "chat",
--       description = "Switch system prompt to explanation-focused",
--       opts = { index = 2 },
--       prompts = {
--         {
--           role = "system",
--           content = function()
--             vim.g.cc_system_prompt = "You explain Python code precisely and concisely, one paragraph max, no filler."
--             return "Explain mode set."
--           end,
--         },
--       },
--     },
--   },
-- })
