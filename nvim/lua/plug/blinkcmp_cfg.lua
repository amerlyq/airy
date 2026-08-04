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
-- local status, blink = pcall(require, "blink.cmp")
-- if not status then return end
local blink = require "blink.cmp"

-- blink.cmp  V2 uses a new build/download system for the native library.
-- SEE  :h blink-cmp-installation
-- NEED: cd /path/to/blink.cmp && git fetch --tags
--   FAIL? latest update to v2 is mostly untagged
-- require('blink.cmp').download({ force = true, tags = '*' }):pwait()
-- OR: cd /path/to/blink.cmp && cargo build --release
-- OR: require('plug.blinkcmp_build').build_if_needed()
-- USAGE:(./recache): $ BLINKCMP_REBUILD=1 nvim --headless -c "qa"
--   OR: nvim --headless -c "lua require('blink.cmp').build():pwait()" -c "qa"
if vim.env.BLINKCMP_REBUILD == "1" then
  blink.build():pwait()
end
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
local cfg = {
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
    ['<C-t>']    = { 'hide' },
    ['<CR>']      = { 'accept', 'fallback' },

    -- Keep the nvim-cmp navigation muscle memory.
    ['<Up>']   = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-p>']  = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>']  = { 'select_next', 'fallback_to_mappings' },
    ['<C-q>']  = { 'show_signature', 'hide_signature', 'fallback' },

    ['<Tab>'] = {
      -- MAYBE: chain same <Tab> for both FIM and Blink
      -- function()
      --   local ok, vact = pcall(function() return require('minuet.virtualtext').action end)
      --   if ok and vact.is_visible() then vact.accept_line(); return true end
      -- end,

      -- Accept the selected item; if none is selected, accept the first item.
      'select_and_accept',
      function()
        if require('luasnip').expand_or_locally_jumpable() then
          require('luasnip').expand_or_jump()
          return true
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

    -- DFL: C-b/C-f
    ['<PageUp>'] = { 'scroll_documentation_up', 'fallback' },
    ['<PageDown>'] = { 'scroll_documentation_down', 'fallback' },
  },

  -- Link blink natively to the standard LuaSnip engine
  snippets = {
    preset = 'luasnip',
  },

  completion = {
    list = {
      -- Match nvim-cmp: navigating highlights an item but does not insert it.
      selection = { preselect = false, auto_insert = false },
      max_items = 40,
    },
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'dictionary'}, --
    -- Match the old nvim-cmp Python setup: no buffer/path noise for members.
    -- per_filetype = { python = { 'lsp', 'snippets' } },
    providers = {
    -- Optional but highly recommended: adjust weights so paths don't crowd LSP completions
    --   lsp = { score_offset = 90 },
    --   path = { score_offset = 80 },
    --   snippets = { score_offset = 70 },
    --   buffer = { score_offset = 50 },

      -- DEBUG: :lua print(vim.inspect(require('blink.cmp.config').sources.providers))
      dictionary = {
        -- SRC:※⡪⡰⣂⡗ https://github.com/Kaiser-Yang/blink-cmp-dictionary
        module = 'blink-cmp-dictionary',
        name = 'Dict',
        min_keyword_length = 1,  -- NEED: >=3 for (rg/grep) PERF
        -- max_items = 8, -- blink-cmp-dictionary will inherit this, the default is 100
        opts = {
          force_fallback = false,  -- Try rg/grep instead of fallback when fzf is not found
          -- WARN: No dedup, so avoid overlapping wordlists.
          dictionary_files = {
            -- ALT? https://github.com/dwyl/english-words
            -- DEP:(!wn): $ auri wordnet-common
            -- DEBUG:
            --   wn idea -over
            --   :checkhealth blink-cmp-dictionary   " in nvim, confirms wn is detected
            -- DEP: $ paci words  -- OR:(ubuntu): $ apti wamerican
            '/usr/share/dict/words',
            -- DEP: $ auri dict-moby-thesaurus
            --   NEED: $ zcat /usr/share/dictd/moby-thesaurus.dict.dz | grep -oP '^\S+' > ~/.local/share/dict/moby-thesaurus.txt
            -- vim.fn.expand('~/.local/share/dict/moby-thesaurus.txt'),
            -- vim.fn.expand('~/.local/share/dict/collins-cobuild.txt'),
          },
          -- dictionary_directories = {
          --   vim.fn.expand('~/.local/share/dict/extra'),  -- all *.txt in here, auto-included
          -- },
        },
      },
    },
  },

  fuzzy = {
    -- `label` makes equal LSP scores deterministic. The prior default stopped
    -- at `sort_text`, which Python servers often omit for member completions.
    sorts = { 'exact', 'score', 'sort_text', 'label' },
    frecency = { enabled = false },
    use_proximity = false,
  },

  -- Signature help appears for `(` and `,`, updates while typing arguments,
  -- and can always be toggled with <C-h>.
  signature = {
    enabled = true,
    trigger = {
      show_on_keyword = true,
      -- REGR: show_on_accept = true,
    },
    window = { show_documentation = true },
  },
}


local ai_offline = require('plug.ai_offline')

if ai_offline.has.minuet then
  -- ['<A-y>'] = require('minuet').make_blink_map(),
  -- OR? <C-_>
  cfg.keymap['<C-?>'] = require('minuet').make_blink_map()
  -- Recommended to avoid unnecessary request with minuet
  cfg.completion.trigger = { prefetch_on_insert = false }
  -- Enable minuet for autocomplete
  table.insert(cfg.sources.default, 'minuet')
  -- For manual completion only, remove 'minuet' from default
  cfg.sources.providers.minuet = {
    name = 'minuet',
    module = 'minuet.blink',
    async = true,
    -- Should match minuet.config.request_timeout * 1000,
    -- since minuet.config.request_timeout is in seconds
    timeout_ms = 3000,
    score_offset = 50, -- Gives minuet higher priority among suggestions
  }
end

blink.setup(cfg)


-- -- Use this function to check if the cursor is inside a comment block
-- local function inside_comment_block()
--     if vim.api.nvim_get_mode().mode ~= 'i' then
--         return false
--     end
--     local node_under_cursor = vim.treesitter.get_node()
--     local parser = vim.treesitter.get_parser(nil, nil, { error = false })
--     local query = vim.treesitter.query.get(vim.bo.filetype, 'highlights')
--     if not parser or not node_under_cursor or not query then
--         return false
--     end
--     local row, col = unpack(vim.api.nvim_win_get_cursor(0))
--     row = row - 1
--     for id, node, _ in query:iter_captures(node_under_cursor, 0, row, row + 1) do
--         if query.captures[id]:find('comment') then
--             local start_row, start_col, end_row, end_col = node:range()
--             if start_row <= row and row <= end_row then
--                 if start_row == row and end_row == row then
--                     if start_col <= col and col <= end_col then
--                         return true
--                     end
--                 elseif start_row == row then
--                     if start_col <= col then
--                         return true
--                     end
--                 elseif end_row == row then
--                     if col <= end_col then
--                         return true
--                     end
--                 else
--                     return true
--                 end
--             end
--         end
--     end
--     return false
-- end
--
-- -- this is the opts for blink.cmp
-- ---@module 'blink.cmp'
-- ---@type blink.cmp.Config
-- opts = {
--     sources = {
--         default = function()
--             -- put those which will be shown always
--             local result = {'lsp', 'path', 'luasnip', 'buffer' }
--             if
--                 -- turn on dictionary in markdown or text file
--                 vim.tbl_contains({ 'markdown', 'text' }, vim.bo.filetype) or
--                 -- or turn on dictionary if cursor is in the comment block
--                 inside_comment_block()
--             then
--                 table.insert(result, 'dictionary')
--             end
--             return result
--         end,
--     }
-- }
