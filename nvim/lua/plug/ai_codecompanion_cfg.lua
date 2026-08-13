-- SRC: https://github.com/olimorris/codecompanion.nvim
--   * Uses dynamic variables like @files, @buffers, @lsp (to pull AST
--     diagnostic/type graphs), and @git to pass precise, bounded codebase
--     context into your local LLM.
-- Fits well alongside local vector search or local MCP servers.

-- CFG: Env vars (put in shell rc or .env sourced before nvim launches):
-- export OPENROUTER_API_KEY="sk-or-v1-..."
-- export GEMINI_API_KEY="AIza..."


-- USAGE:WF:(agentic-like): open :CodeCompanionChat
--   @full_stack_dev Scan the repo, find the bug causing <test/error>.
--   Edit files with insert_edit_into_file, then run the test suite with run_command.
--   If it fails, read the output and fix again. Repeat until it passes.
--
-- * LLM decides scan→edit→run→analyze→repeat on its own turn-by-turn, using tool calls.
--   State = the chat buffer (full conversation + tool results persist there).
--     : For large repos approaching context limits,
--     opts.memory/context-compaction settings in config (trigger, keep_cycles,
--     min_token_savings) auto-summarize older tool cycles rather than dropping them
-- * Autonomous YOLO mode (no manual "continue" after each tool call)
--   require("codecompanion.interactions.chat.tools.approvals"):toggle_yolo_mode()
-- * Automated retry loop — use the built-in Edit<->Test workflow
--    (ships with the plugin, :CodeCompanionActions → workflow),
--    or define your own: 'opts = { prompt_library = { ["Bugfix Loop"] = { ...'
--   : The workflow mechanism auto-resubmits the prompt on tool-result events
--   (subscription-based), so it re-triggers edit→test until the LLM reports
--   pass — that's your repeat loop, no external harness.

-- local ok, codecompanion = pcall(require, "codecompanion")
-- if not ok then return end

local CC = require("codecompanion")
CC.setup({
  -- opts = {
  --   log_level = "TRACE",  -- DEBUG may not capture full curl invocation; TRACE does
  -- },

  interactions = {
    chat = {
      -- adapter = {
      --   name = "codex_docker",
      --   -- model = "gpt-5.6-sol",
      -- },
      -- keymaps = {
      --   send = false,  -- DFL=<C-s>
      --   close = false  -- DFL=<C-c>
      -- }
    },
    -- cli = {
    --   agent = "codex_docker",
    --   agents = {
    --     claude_code = {
    --       cmd = "claude",
    --       args = {},
    --       description = "Claude Code CLI",
    --     },
    --     codex_docker = {
    --       cmd = "codex",
    --       args = {},
    --       description = "OpenAI Codex CLI",
    --     },
    --   },
    -- },
  },
  strategies = {
    chat = {
      -- adapter = "ollama",
      adapter = "openrouter",
      -- adapter = "codex_docker",
      -- opts = {
      --   system_prompt = function(opts)
      --     return "python3.14+typehints, no boilerplate, no explanations, only correct code and comments"
      --     -- USAGE:(per tasks series): :lua vim.g.cc_system_prompt = "..."
      --     -- return vim.g.cc_system_prompt or "default terse python prompt"
      --   end,
      -- }
    },
    inline = {
      -- adapter = "ollama",
      adapter = "openrouter",
      -- FAIL: ACP adapters are NOT supported for inline interaction.
      --   Keep an HTTP adapter here if you use :CodeCompanion.
      --   ERR: [adapters::http::extend] Adapter not found: codex
      -- adapter = "codex_docker",
    },
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
              -- default = "anthropic/claude-sonnet-4.6"
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
    acp = {
      -- FAIL: "codex" not found -- if presents are hidden
      -- opts = {
      --   show_presets = false,
      -- },
      codex_docker = function()
        return require("codecompanion.adapters").extend("codex", {
          name = "codex_docker",
          commands = {
            -- NEED: codex-acp inside /d/airy/ai/run
            --   $ cd /t && git clone --depth=1 https://github.com/agentclientprotocol/codex-acp.git
            --   $ docker pull oven/bun:slim
            --   $ cd ./codex-acp && docker run --rm --init --ulimit memlock=-1:-1 -v "$PWD:$PWD" -w "$PWD" oven/bun:slim \
            --     sh -c "bun install && bun build src/index.ts --minify --sourcemap --compile --target=bun-linux-x64-baseline --outfile dist/bin/codex-acp"
            --   $ /d/airy/ai/run --name=codex_docker --mnt=/t/codex-acp/dist/bin/codex-acp:/b/codex-acp [--codex] --wkdir="$PWD" -- "$PWD" CODEX_PATH=/b/codex
            -- DEBUG
            --   $ docker exec -it codex_docer -- codex exec 'say OK'
            --   $ docker exec -it codex_docer -- codex login status
            default = { "docker", "exec", "-i",
              -- "-e", [[CODEX_CONFIG={"model":"gpt-5.6-terra","model_reasoning_effort":"low"}]],
              "codex_docker", "codex-acp", },
          },
          defaults = {
            auth_method = "chat-gpt",
            session_config_options = {
              -- ga → choose/switch model
              -- /acp_session_options → choose reasoning effort (thought_level) and other ACP session options
              -- gd → debug window; shows current model/session config
              model = "gpt-5.6-luna",
              -- model = function(self) return "gpt-5.6-luna" end,
              thought_level = "low",
            },
          },
        })
      end,
    },
  },
})

-- FIXED:AGAIN: Force filetype detection for all buffers
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyPluginsLoaded",
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                local ft = vim.bo[buf].filetype
                if ft then
                    vim.api.nvim_buf_set_option(buf, "filetype", ft)
                end
            end
        end
    end
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local excluded_filetypes = {
      "nou",
      -- "help",
      -- "terminal",
      -- "toggleterm",
      -- "NvimTree",
      -- "neo-tree",
      -- "lazy",
      -- "mason",
    }
    local ft = vim.bo[args.buf].filetype

    if vim.tbl_contains(excluded_filetypes, ft) then
      return
    end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, noremap = true, silent = true, desc = desc })
    end

    map({ "n", "v" }, "<Space>c", "<Cmd>CodeCompanionChat Toggle<CR>", "AI Chat")
    map({ "n", "v" }, "<Space>i", "<Cmd>CodeCompanion<CR>", "AI Inline Prompt")
    map({ "n", "v" }, "<Space>a", "<Cmd>CodeCompanionActions<CR>", "AI Actions")
    map("v", "<Space>e", ":CodeCompanion /fix<CR>", "AI Fix Selected Code")
    map("v", "<Space>v", ":CodeCompanionChat Add<CR>", "AI Send selection to ACP")
    -- map({ "n", "v" }, "<Space>v", function() return CC.cli("#{this}", { focus = false }) end, "Add context to the CLI agent")
    map({ "n", "v" }, "<Space>l", function() return CC.cli({ prompt = true }) end, "Prompt the CLI agent")

    map("n", "<Space>d", function()
      return CC.cli("#{diagnostics} Can you fix these?", { focus = false, submit = true })
    end, "Send diagnostics to CLI agent")

    map("n", "<Space>t", function()
      return CC.cli("#{terminal} Sharing the output from the terminal. Can you fix it?", { focus = false, submit = true })
    end, "Send terminal output to CLI agent")

    map("n", "<Space>i", function() CC.prompt("docs") end, "AI 'docs'")

    -- USAGE:(switch): :CodeCompanionChat Adapter [ollama|openrouter|gemini]
    -- map("n", "<Space>ao", function() CC.adapters.set("openrouter") end, "CC: OpenRouter" })
    -- map("n", "<Space>al", function() CC.adapters.set("ollama") end, "CC: Ollama (local)" })
    -- map("n", "<Space>ag", function() CC.adapters.set("gemini") end, "CC: Gemini" })
  end,
})

-- DISABLED:WTF: expanded even in "/" menu
-- Expand 'C' into 'CodeCompanion' in the command line
-- vim.cmd([[cab C CodeCompanion]])

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

-- https://github.com/olimorris/codecompanion.nvim/discussions/1209
-- local PROMPT_LIBRARY = {
--   ['Improve Copy'] = {
--     strategy = 'inline',
--     description = 'Improves the copy of the page',
--     -- opts = {
--     --   mapping = '<LocalLeader>ch',
--     -- },
--     prompts = {
--       {
--         role = 'system',
--         content = [[You are an experienced developer, designer and creator. Your build useful products that people love to use. Your task is to improve the copy of the content to bring more clarity and improve conversions.]],
--       },
--       {
--         role = 'user',
--         content = '#buffer\n\nPlease improve the copy of the page.',
--       },
--     },
--   },
--   ['Review the code'] = {
--     strategy = 'inline',
--     description = 'Review the code in buffer',
--     -- opts = {
--     --   mapping = '<LocalLeader>ch',
--     -- },
--     prompts = {
--       {
--         role = 'system',
--         content = [[You are an experienced senior developer. You do code reviews.]],
--       },
--       {
--         role = 'user',
--         content = '#buffer\n\nPlease review the code in the file and make the fixes if any.',
--       },
--     },
--   },
-- }


-- opts = {
--   prompt_library = {
--     ["Bugfix Loop"] = {
--       strategy = "workflow",
--       description = "Scan, fix, test, repeat until green",
--       opts = { index = 10, is_default = true, short_name = "bugfix" },
--       prompts = {
--         {
--           {
--             name = "Setup",
--             role = "user",
--             opts = { auto_submit = false },
--             content = function()
--               require("codecompanion.interactions.chat.tools.approvals"):toggle_yolo_mode()
--               return [[
-- ### Instructions
-- Find and fix the bug in this repo (context: <describe symptom/test>).
--
-- ### Steps
-- 1. Search the codebase to locate the fault using @{file_search}/@{grep_search}.
-- 2. Apply a fix using @{insert_edit_into_file}.
-- 3. Run the test suite with @{run_command} (`<your test cmd>`).
-- 4. If failing, analyze output and go to step 2. If passing, stop and summarize the fix.
-- ]]
--             end,
--           },
--         },
--       },
--     },
--   },
-- }
