local K = require 'keys.bind'.K

-- FAIL: looks like gitsigns.is_hl_set() check is wrong -- TEMP: use fallback grps
-- vim.api.nvim_set_hl(0, 'GitSignsChangeLn', { fg = '#b58900', bg = '#000000', sp = '#b58900', underline = true })

-- Gitsigns
-- Add git related info in the signs columns and popups
--DEP: plenary.nvim
--SRC: https://github.com/lewis6991/gitsigns.nvim
--USAGE:
-- :Gitsigns diffthis HEAD~1
-- :Gitsigns blame_line
-- :Gitsigns toggle_signs
-- :Gitsigns toggle_current_line_blame
-- :Gitsigns change_base ~
-- :Gitsigns reset_buffer
-- :Gitsigns change_base nil true
local M = require('gitsigns')
-- vim.opt.signcolumn = 'number'
M.setup {
  -- DONE: show gitsign as a color/bkgr of cur lineno (for narrow windows) ※⡢⢹⢓⠓※⡢⢹⢐⣓
  --   MAYBE:BET: chg numhl bg= inof fg=
  signcolumn = false, -- Toggle with `:Gitsigns toggle_signs`
  numhl      = true, -- Toggle with `:Gitsigns toggle_numhl`
  -- linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  -- word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  -- current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  signs      = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    -- if vim.api.nvim_buf_get_name(bufnr):match(<PATTERN>) then
    --   -- Don't attach to specific buffers whose name matches a pattern
    --   return false
    -- end

    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        -- BAD: doesn't work for arbitrary unified ft=diff from stdin
        -- OR:(M): local M = package.loaded.gitsigns
        M.nav_hunk('next')  -- , { wrap = false, preview = true }
      end
    end, { buffer = bufnr, desc = "hunk↓ (gitsigns → :vimdiff)" })

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        M.nav_hunk('prev')
      end
    end, { buffer = bufnr, desc = "hunk↑ (gitsigns → :vimdiff)" })

    vim.keymap.set('n', '[C', function()
      if vim.wo.diff then
        vim.cmd.normal({ '9999[c', bang = true })
      else
        gs.nav_hunk('first')
      end
    end, { buffer = bufnr, desc = "hunk1 (gitsigns → :vimdiff)" })

    vim.keymap.set('n', ']C', function()
      if vim.wo.diff then
        vim.cmd.normal({ '9999]c', bang = true })
      else
        gs.nav_hunk('last')
      end
    end, { buffer = bufnr, desc = "hunk$ (gitsigns → :vimdiff)" })

  end,
}

-- DISABLE: [{'name': 'GitSignsAdd', 'numhl': 'false', 'texthl': 'GitSignsAdd', 'linehl': 'false'}]
-- config.signcolumn = false and config.numhl == false and config.linehl == false
-- and vim.wo.signcolumn == 'number'
