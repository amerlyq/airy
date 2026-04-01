-- Minimal config (only non-default overrides)

local command = {
  -- Custom command to start OpenCode in Docker instead of local binary
  -- "docker", "run", "-it", "--rm", "--name=opencode-server",
  -- "-v", vim.fn.expand("~/.config/opencode") .. ":/home/ubuntu/.config/opencode", -- Persistent config
  -- -v "$HOME/.local/share/opencode/auth.json":/home/ubuntu/.local/share/opencode/auth.json
  -- "-v", vim.fn.getcwd() .. ":/w",  -- Mount current project
  -- "-w", "/w",
  -- "-p 4096:4096 "
  -- "ghcr.io/anomalyco/opencode:latest",
  -- "opencode", "serve", "--port", "4096"
  "env", "--chdir=/d/airy/ai", "/d/airy/ai/run",
}

require("opencode").setup({
  default_mode = "plan",  -- DFL=build

  -- ALT:REF: https://docs.docker.com/reference/cli/docker/sandbox/create/opencode/
  -- $ docker sandbox create --name my-opencode opencode /g/my_gen
  -- $ docker sandbox run my-opencode
  -- server = {
  --   -- Override the default start function to run Docker
  --   start = function()
  --     local cmd = "env --chdir=/d/airy/ai /d/airy/ai/run opencode serve --port 4096"
  --     -- Open in a terminal buffer to allow for authentication if needed
  --     vim.cmd("split | terminal " .. cmd)
  --   end,
  --   -- Match the port used in the docker command
  --   host = "127.0.0.1",
  --   port = 4096,
  -- },

  keymaps = {
    -- Explicit open/close (so you don't depend on defaults)
    open = "<leader>oC",
    close = "<leader>oc",

    -- Mode control: Plan <-> Build (your architectural gate)
    switch_mode = "<leader>om",

    -- Diff navigation for fast single-pass review
    diff_open = "<leader>od",
    diff_next = "]e",
    diff_prev = "[e",

    -- Revert just the last AI step (prompt-granular undo)
    diff_revert_all_last_prompt = "<leader>oR",
    diff_revert_this_last_prompt = "<leader>or",

    -- Context steering (tight iteration cleanup loop)
    add_visual_selection = "<leader>oa",
    clear_context = "<leader>oX",

    -- Intentionally NOT setting quick_chat (o/)
    -- to avoid auto-applied edits workflow.
  },
})


-- dependencies = {
--   "nvim-lua/plenary.nvim",
--   {
--     "MeanderingProgrammer/render-markdown.nvim",
--     opts = {
--       anti_conceal = { enabled = false },
--       file_types = { 'markdown', 'opencode_output' },
--     },
--     ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
--   },
--   -- Optional, for file mentions and commands completion, pick only one
--   'saghen/blink.cmp',
--   -- 'hrsh7th/nvim-cmp',
--
--   -- Optional, for file mentions picker, pick only one
--   'folke/snacks.nvim',
--   -- 'nvim-telescope/telescope.nvim',
--   -- 'ibhagwan/fzf-lua',
--   -- 'nvim_mini/mini.nvim',
-- },
