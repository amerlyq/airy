-- SRC: completion as-you-type from popular LLMs including OpenAI, Gemini, Claude, Ollama,  ⌇⡪⡪⠷⠰
--   https://github.com/milanglacier/minuet-ai.nvim
--   * Native Fill-In-The-Middle (FIM) inline/ghost-text completion.

-- DEPs
-- { 'hrsh7th/nvim-cmp' }, -- optional, if you are using virtual-text frontend, nvim-cmp is not required.
-- { 'Saghen/blink.cmp' }, -- optional, if you are using virtual-text frontend, blink is not required.

-- DEBUG:
-- $ curl -X POST http://localhost:11434/api/generate -d '{
--   "model": "qwen2.5-coder:14b",
--   "prompt": "def add(a, b):\n    ",
--   "stream": false
-- }'
-- $ curl -X POST http://localhost:11434/v1/chat/completions \
--   -H "Content-Type: application/json" \
--   -d '{
--     "model": "qwen2.5-coder:14b",
--     "messages": [{"role": "user", "content": "say hi"}]
--   }'

-- ::end_point::
-- http://localhost:11434/v1/completions (Legacy/Text Endpoint):
--   Accepts a single string prompt and returns text continuation. This is
--   required for Fill-in-the-Middle (FIM) code completion because Minuet can
--   format the prefix/suffix prompt tokens manually and send them directly to
--   qwen2.5-coder.
-- http://localhost:11434/v1/chat/completions (Chat Endpoint):
--   Expects structured message objects ([{"role": "user", "content": "..."}]).
--   If you send raw FIM template strings to a chat endpoint, the server tries
--   to format it as a conversation, breaking FIM completion.
-- http://127.0.0.1:11434/api/generate
--   That endpoint expects raw Ollama JSON schema, while openai_fim_compatible
--   expects an OpenAI-styled payload (/v1/completions).

-- local function test()

require('minuet').setup({
  -- provider = 'gemini'
  provider = 'openai_fim_compatible',
  request_timeout = 10, -- Give Ollama 10s instead of defaulting to 3s
  -- FUT:
  -- -- I recommend beginning with a small context window size and incrementally
  -- -- expanding it, depending on your local computing power. A context window
  -- -- of 512, serves as an good starting point to estimate your computing
  -- -- power. Once you have a reliable estimate of your local computing power,
  -- -- you should adjust the context window to a larger value.
  context_window = 512,
  -- context_window = 2048,
  n_completions = 1, -- recommend for local model for resource saving

  -- 1. Enable automatic triggering as you type
  throttle = 1000, -- Wait 1000ms after you stop typing before requesting completion
  debounce = 400,   -- Debounce time between keystrokes, set to 0 to disble



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
      end_point = 'http://127.0.0.1:11434/v1/completions', -- Must be /v1/completions
      optional = {
        max_tokens = 256,
        -- max_tokens = 56,  -- for :7b
        top_p = 0.9,
      },
      -- Uses FIM (Fill-in-the-Middle) formatting for accurate completions
      -- template = {
      --   prompt = '{{{prompt}}}',
      --   suffix = '{{{suffix}}}',
      -- },
    },
  },
  virtualtext = {
    -- Note that you can still invoke manual completion even if the filetype is not on your auto_trigger_ft list.
    -- auto_trigger_ft = { 'python', 'c', 'cpp', 'lua' }, -- Enable ghost text for python/systems code
    auto_trigger_ft = { '*' },
    -- useful when auto-completion is enabled for all file types i.e., when auto_trigger_ft = { '*' }
    auto_trigger_ignore_ft = {},
    -- Blink normally opens its menu while typing; keep the FIM ghost text
    -- visible instead of suppressing it whenever that menu is present.
    show_on_completion_menu = true,
    keymap = {
      -- ALT: accept = '<A-a>',     -- Alt+a to accept ghost text
      -- ALT: accept_line = '<A-l>',-- Alt+l to accept just one line
      accept = '<A-A>', -- accept whole completion
      accept_line = '<A-a>', -- accept one line
      accept_n_lines = '<A-z>', -- accept n lines (prompts for number) e.g. "A-z 2 CR" will accept 2 lines
      prev = '<A-[>', -- Cycle to prev completion item, or manually invoke completion
      next = '<A-]>', -- Cycle to next completion item, or manually invoke completion
      dismiss = '<A-e>',
    },
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


-- Accept FIM only when it is still visible at the typing position. Once the
-- cursor has moved (arrows, <C-b>, etc.), Minuet clears the preview and this
-- returns the normal insert-mode <C-f> character-forward command instead.
vim.keymap.set('i', '<C-f>', function()
  local virtualtext = require('minuet.virtualtext')
  if virtualtext.action.is_visible() then
    virtualtext.action.accept()
    return ''
  end
  return vim.keycode('<C-f>')
end, { expr = true, desc = '[minuet] accept FIM or move forward' })


-- vim.keymap.set('i', '<A-x>', function() vim.lsp.inline_completion.get() end, { desc = 'accept' })
-- vim.keymap.set('i', '<A-c>', function() vim.lsp.inline_completion.select { count = 1 } end, { desc = 'cycle to next' })
-- vim.keymap.set('i', '<A-v>', function() vim.lsp.inline_completion.select { count = -1 } end, { desc = 'cycle to prev' })


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
