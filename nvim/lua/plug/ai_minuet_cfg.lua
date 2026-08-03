-- SRC: completion as-you-type from popular LLMs including OpenAI, Gemini, Claude, Ollama,  ⌇⡪⡪⠷⠰
--   https://github.com/milanglacier/minuet-ai.nvim
--   * Native Fill-In-The-Middle (FIM) inline/ghost-text completion.

-- DEPs
-- { 'hrsh7th/nvim-cmp' }, -- optional, if you are using virtual-text frontend, nvim-cmp is not required.
-- { 'Saghen/blink.cmp' }, -- optional, if you are using virtual-text frontend, blink is not required.

require('minuet').setup({
  enable_predicates = {
    function()
      -- ALT: check if it's back
      -- local now = vim.uv.hrtime() / 1e6
      -- if now - last_check > check_interval_ms then
      --   last_check = now
      --   -- WARN: async -- doesn't block this call
      --   require('plug.ai_offline').refresh_ollama_status()
      -- end
      return require('plug.ai_offline').ollama_reachable == true
    end,
  },

  -- provider = 'gemini'
  provider = 'openai_fim_compatible',
  -- FUT:
  -- -- I recommend beginning with a small context window size and incrementally
  -- -- expanding it, depending on your local computing power. A context window
  -- -- of 512, serves as an good starting point to estimate your computing
  -- -- power. Once you have a reliable estimate of your local computing power,
  -- -- you should adjust the context window to a larger value.
  -- context_window = 512,
  -- context_window = 2048,
  -- MAYBE: setting minuet's to 4096 while the model supports 12288 gives headroom
  --   for codecompanion's chat context to use the rest without minuet's FIM requests starving it.

  -- the maximum total characters of the context before and after the cursor
  -- DFL=16000 characters typically equate to approximately 4,000 tokens for LLMs.
  context_window = 12000,

  n_completions = 1, -- recommend for local model for resource saving

  -- 1. Enable automatic triggering as you type
  throttle = 1000, -- Wait DFL=1000ms after you stop typing before requesting completion
  -- INFO: window where a stale request could still complete before being superseded
  debounce = 400, -- Debounce DFL=400ms time between keystrokes, set to 0 to disable
  request_timeout = 3, -- ALT:(cold start): ollama needs ~10s (inof DFL=3s)


  provider_options = {
    openai_fim_compatible = {
      -- For Windows users, TERM may not be present in environment variables.
      -- Consider using APPDATA instead.
      api_key = 'TERM',
      -- api_key = 'OLLAMA', -- Plain string dummy key for local endpoint
      -- ALT: Point Minuet to your VRAM-bound 7B model for <200ms latency
      -- name = 'Ollama-Fast',
      -- model = 'qwen2.5-coder:7b',
      name = 'Ollama',
      model = 'qwen2.5-coder:14b',
      -- model = 'qwen2.5-coder:14b-12k',  -- use the Modelfile variant
      end_point = 'http://127.0.0.1:11434/v1/completions', -- Must be /v1/completions
      optional = {
        max_tokens = 128,  -- (==num_predict) FIM should stay small/fast, not =256
        -- max_tokens = 56,  -- for :7b
        temperature = 0.1, -- low temp, deterministic FIM
        top_p = 0.9,
      },
      -- system = {
      --   prompt = function() return "..." end,
      -- },
      -- Uses FIM (Fill-in-the-Middle) formatting for accurate completions
      -- template = {
      --   prompt = '{{{prompt}}}',
      --   suffix = '{{{suffix}}}',
      -- },
    },
  },

  virtualtext = {
    -- ALT: avoid errors when ollama isn't running
    --   FAIL: still triggered, presumably by blink
    auto_trigger_ft = {},
    -- Note that you can still invoke manual completion even if the filetype is not on your auto_trigger_ft list.
    -- auto_trigger_ft = { 'python', 'c', 'cpp', 'lua' }, -- Enable ghost text for python/systems code
    -- auto_trigger_ft = { '*' },
    -- useful when auto-completion is enabled for all file types i.e., when auto_trigger_ft = { '*' }
    auto_trigger_ignore_ft = {},
    -- Blink normally opens its menu while typing; keep the FIM ghost text
    -- visible instead of suppressing it whenever that menu is present.
    show_on_completion_menu = true,
    -- keymap = {
    --   -- ALT: accept = '<A-a>',     -- Alt+a to accept ghost text
    --   -- ALT: accept_line = '<A-l>',-- Alt+l to accept just one line
    --   accept = '<A-A>', -- accept whole completion
    --   accept_line = '<A-a>', -- accept one line
    --   accept_n_lines = '<A-z>', -- accept n lines (prompts for number) e.g. "A-z 2 CR" will accept 2 lines
    --   prev = '<A-[>', -- Cycle to prev completion item, or manually invoke completion
    --   next = '<A-]>', -- Cycle to next completion item, or manually invoke completion
    --   dismiss = '<A-e>',
    --   -- ALT:
    --   -- vim.keymap.set('i', '<A-x>', function() vim.lsp.inline_completion.get() end, { desc = 'accept' })
    --   -- vim.keymap.set('i', '<A-c>', function() vim.lsp.inline_completion.select { count = 1 } end, { desc = 'cycle to next' })
    --   -- vim.keymap.set('i', '<A-v>', function() vim.lsp.inline_completion.select { count = -1 } end, { desc = 'cycle to prev' })
    -- },
  },
  -- WARN: For users of blink-cmp and nvim-cmp, it is recommended to use the
  --   native source rather than through LSP for two main reasons:
  --     * better sorting and async management when Minuet is a sep source inof alongside LSP/clangd
  --     * with lsp it's impossible to determine whether completion is triggered automatically or manually
  -- lsp = {
  --   enabled_ft = { 'toml', 'lua', 'cpp' },
  --   -- Filetypes excluded from LSP activation. Useful when `enabled_ft` = { '*' }
  --   disabled_ft = {},
  --   completion = {
  --     -- Enables automatic completion triggering using `vim.lsp.completion.enable`
  --     enabled_auto_trigger_ft = { 'cpp', 'lua' },
  --   },
  --   -- -- ALT: It is recommended to disable completion when use inline_completion
  --   -- completion = { enable = false },
  --   -- inline_completion = {
  --   --     enable = true,
  --   --     enabled_auto_trigger_ft = { 'cpp', 'lua' },
  --   -- },
  -- }
})

-- This configuration is loaded during delayed startup, after the current
-- buffer's FileType event. Minuet normally initializes this flag from a
-- FileType autocmd, so initialize the already-open buffer explicitly.
vim.b.minuet_virtual_text_auto_trigger = true

vim.keymap.set('n', '<leader>ct', '<cmd>Minuet virtualtext toggle<cr>', { desc = '[minuet] toggle auto-trigger' })

-- Accept FIM only when it is still visible at the typing position. Once the
-- cursor has moved (arrows, <C-b>, etc.), Minuet clears the preview and this
-- returns the normal insert-mode <C-f> character-forward command instead.
local vact = require('minuet.virtualtext').action

-- BAD=<i_CTRL-[> -- will break :iabbr
vim.keymap.set('i', '<C-c>', function()
  if vact.is_visible() then vact.dismiss(); return '' end
  return vim.keycode('<C-c>')
end, { expr = true, desc = '[minuet] dismiss FIM or escape' })

-- DFL=<i_CTRL-]> : Trigger abbreviation, without inserting a character.
vim.keymap.set('i', '<C-]>', function()
  if vact.is_visible() then vact.accept(); return '' end
  return vim.keycode('<C-]>')
end, { expr = true, desc = '[minuet] accept whole FIM or move to end' })

-- CHECK: may not even work
vim.keymap.set('i', '<C-;>', function()
  if vact.is_visible() then vact.accept_line(); return '' end
  return vim.keycode('<C-;>')
end, { expr = true, desc = '[minuet] accept line FIM or move forward' })


-- ALT: if you don't use blink.cmp or nvim-cmp
-- -- ====================================================================
-- -- Native Neovim Autocommand: Auto-trigger Minuet Virtual Text on Typing
-- -- ====================================================================
-- local timer = nil
-- vim.api.nvim_create_autocmd("InsertCharPre", {
--   group = vim.api.nvim_create_augroup("MinuetAutoTrigger", { clear = true }),
--   callback = function()
--     -- Debounce: cancel previous timer if typing rapidly
--     if timer then
--       timer:stop()
--       timer:close()
--     end
--
--     timer = vim.uv.new_timer()
--     -- Wait 800ms after you stop typing, then fire Minuet's virtualtext trigger
--     timer:start(800, 0, vim.schedule_wrap(function()
--       if vim.api.nvim_get_mode().mode == 'i' then
--         require('minuet.virtualtext').action.complete()
--       end
--       if timer and not timer:is_closing() then
--         timer:close()
--       end
--     end))
--   end,
-- })
