-- Blink.cmp or nvim-cmp? : r/neovim ⌇⡪⡪⠱⠑
--   https://www.reddit.com/r/neovim/comments/1hi2l7s/blinkcmp_or_nvimcmp/
--   nvim-cmp/lua/cmp/core.lua at b555203ce4bd7ff6192e759af3362f9d217e8c89 · hrsh7th/nvim-cmp · GitHub ⌇⡪⡪⠱⢇
--     https://github.com/hrsh7th/nvim-cmp/blob/b555203ce4bd7ff6192e759af3362f9d217e8c89/lua/cmp/core.lua#L383
--
-- How to replace blink.cmp with nvim-cmp? · LazyVim/LazyVim · Discussion #6388 · GitHub ⌇⡪⡪⠱⢢
--   https://github.com/LazyVim/LazyVim/discussions/6388
--
-- nvim.cmp vs blink.cmp : r/neovim ⌇⡪⡪⠱⣖
--   https://www.reddit.com/r/neovim/comments/1jnq28d/nvimcmp_vs_blinkcmp/

-- TRY?
-- GitHub - jake-stewart/multicursor.nvim: multiple cursors in neovim · GitHub ⌇⡪⡪⠲⠽
--   https://github.com/jake-stewart/multicursor.nvim
--   OLD:(but sup autocomplete): https://github.com/mg979/vim-visual-multi
--   TALK: https://www.reddit.com/r/neovim/comments/1jnq28d/nvimcmp_vs_blinkcmp/
--
-- TRY?
-- GitHub - mrjones2014/smart-splits.nvim: 🧠 Smart, seamless, directional navigation and resizing of Neovim + terminal multiplexer splits. Supports Zellij, Tmux, Wezterm, and Kitty. T ⌇⡪⡪⠴⠜
--   https://github.com/mrjones2014/smart-splits.nvim


-- dependencies = {
--   'saghen/blink.lib',
--   -- optional: provides snippets for the snippet source
--   'rafamadriz/friendly-snippets',
-- },


-- Ensure blink.cmp is loaded before attempting setup
local status, blink = pcall(require, "blink.cmp")
if not status then return end

-- blink.cmp  V2 uses a new build/download system for the native library.
-- SEE  :h blink-cmp-installation
-- NEED: cd /path/to/blink.cmp && git fetch --tags
--   FAIL? latest update to v2 is mostly untagged
-- require('blink.cmp').download({ force = true, tags = '*' }):pwait()
-- OR: cd /path/to/blink.cmp && cargo build --release
require('blink.cmp').build():pwait()
-- require('blink.cmp.native').build()
-- vim.system(
--   { 'cargo', 'build', '--release' },
--   { cwd = '/cache/plugins/nvim/all/blink.cmp' }
-- ):wait()


 -- blink.cmp  Failed to build blink.cmp native library: Failed with exit code 101: error: could not find `Cargo.toml` in `/cache/plugins` or any parent directory
-- local original_cwd = vim.uv.cwd() -- OLD: vim.fn.getcwd()
-- vim.api.nvim_set_current_dir('/d/plugins/nvim/preload/pack/startup/start/blink.cmp')
-- blink.build():pwait()
-- vim.api.nvim_set_current_dir(original_cwd)


-- CFG:SEIZE
-- blink vs nvim.cmp · GitHub ⌇⡪⡪⠱⣼
--   https://gist.github.com/mhartington/d2e757e1cdb2ed678ee755de640050a0
-- blink.cmp vs nvim-cmp · GitHub ⌇⡪⡪⠲⠊
--   https://gist.github.com/Saghen/e731f6f6e30a4c01f6bc7cdaa389d463
blink.setup({
  -- Keymaps optimized for explicit manual setups with LuaSnip fallback behavior
  keymap = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    preset = 'none', -- We clear the preset to ensure exact mapping control

    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>']     = { 'hide' },
    ['<CR>']      = { 'accept', 'fallback' },

    ['<Tab>'] = {
      function(cmp)
        if cmp.is_visible() then
          return cmp.select_next()
        -- Directly query LuaSnip engine using explicit pathing
        elseif require('luasnip').expand_or_locally_jumpable() then
          return require('luasnip').expand_or_jump()
        end
      end,
      'fallback',
    },
    ['<S-Tab>'] = {
      function(cmp)
        if cmp.is_visible() then
          return cmp.select_prev()
        elseif require('luasnip').locally_jumpable(-1) then
          return require('luasnip').jump(-1)
        end
      end,
      'fallback',
    },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  },

  -- Link blink natively to the standard LuaSnip engine
  snippets = {
    preset = 'luasnip',
  },

  -- (Default) Only show the documentation popup when manually triggered
  -- completion = { documentation = { auto_show = false } },

  -- (Default) list of enabled providers defined so that you can extend it
  -- elsewhere in your config, without redefining it, due to `opts_extend`
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },

    -- Optional but highly recommended: adjust weights so paths don't crowd LSP completions
    providers = {
      lsp = { score_offset = 90 },
      path = { score_offset = 80 },
      snippets = { score_offset = 70 },
      buffer = { score_offset = 50 },
    },
  },

  -- Enable signature help globally (argument popups inside parentheses)
  signature = { enabled = true }
})
