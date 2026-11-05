-- # Core Plugin & Mandatory Dependencies
-- git submodule add https://github.com pack/plugins/start/avante.nvim
-- git submodule add https://github.com pack/plugins/start/plenary.nvim
-- git submodule add https://github.com pack/plugins/start/nui.nvim
-- git submodule add https://github.com pack/plugins/start/mega.logging
-- git submodule add https://github.com pack/plugins/start/mega.cmdparse
--
-- # Integrations, Providers & Icons
-- git submodule add https://github.com pack/plugins/start/mini.pick
-- git submodule add https://github.com pack/plugins/start/telescope.nvim
-- git submodule add https://github.com pack/plugins/start/nvim-cmp
-- git submodule add https://github.com pack/plugins/start/fzf-lua
-- git submodule add https://github.com pack/plugins/start/snacks.nvim
-- git submodule add https://github.com pack/plugins/start/nvim-web-devicons
-- git submodule add https://github.com pack/plugins/start/copilot.lua
-- git submodule add https://github.com pack/plugins/start/img-clip.nvim
-- git submodule add https://github.com pack/plugins/start/render-markdown.nvim
--
-- OR: powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false
-- $ make -C pack/plugins/start/avante.nvim


-- ==========================================================================
-- 1. PLUGIN SETUP & CONFIGURATIONS
-- ==========================================================================

-- Setup img-clip.nvim
require("img-clip").setup({
  default = {
    embed_image_as_base64 = false,
    prompt_for_file_name = false,
    drag_and_drop = {
      insert_mode = true,
    },
    use_absolute_path = true, -- required for Windows users
  },
})

-- Setup render-markdown.nvim
require("render-markdown").setup({
  file_types = {
    "markdown",
    "markdown.Avante", -- Workaround for multiple filetypes bug
  },
})

-- Setup avante.nvim
require("avante").setup({
  instructions_file = "avante.md",
  provider = "claude",
  providers = {
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-sonnet-4-20250514",
      timeout = 30000,
      extra_request_body = {
        temperature = 0.75,
        max_tokens = 20480,
      },
    },
    moonshot = {
      endpoint = "https://api.moonshot.ai/v1",
      model = "kimi-k2-0711-preview",
      timeout = 30000,
      extra_request_body = {
        temperature = 0.75,
        max_tokens = 32768,
      },
    },
  },
})

-- ==========================================================================
-- 2. FILETYPE AUTOCMDS (Replacing Lazy's `ft = ...`)
-- ==========================================================================
-- Replicates lazy's lazy-loading trigger for render-markdown filetypes
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown", "Avante" },
  callback = function()
    -- Native packages under 'start/' load automatically, but if you notice
    -- any missing components you can force-load or refresh plugins here.
  end,
})



-- BET? ==========================================================================
-- Global statusline required for collapsing Avante windows
vim.opt.laststatus = 3

-- Companion setup for image pasting, markdown preview, and icons
require("img-clip").setup({ default = { embed_image_as_base64 = false, prompt_for_file_name = false, use_absolute_path = true } })
require("render-markdown").setup({ file_types = { "markdown", "markdown.Avante" } })
require("nvim-web-devicons").setup({})

-- Main Avante configuration
require("avante").setup({
  provider = "claude",
  auto_suggestions_provider = "claude",
  mode = "agentic",
  instructions_file = "avante.md",
  providers = {
    claude = {
      endpoint = "https://anthropic.com",
      model = "claude-3-5-sonnet-20241022",
      timeout = 30000,
      extra_request_body = { temperature = 0, max_tokens = 4096 },
    },
  },
  behaviour = {
    auto_suggestions = false,
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    support_paste_from_clipboard = true,
    minimize_diff = true,
    enable_token_counting = true,
    auto_add_current_file = true,
    auto_approve_tool_permissions = true,
  },
  windows = { position = "right", wrap = true, width = 30 },
  input = { provider = "snacks", provider_opts = { title = " Avante Input " } },
  selector = { provider = "fzf", provider_opts = {} },
})


-- With auto_set_keymaps = true enabled, these shortcuts are mapped automatically:
-- • <leader>aa — Opens the AI Sidebar chat panel.
-- • <leader>at — Toggles sidebar visibility.
-- • co — Accepts our current code changes during a conflict.
-- • ct — Accepts their AI-suggested code changes during a conflict.
-- • ]x / [x — Navigates between project conflict blocks.
