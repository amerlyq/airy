
-- OR? local K = require'keys.bind'.K
local KS = vim.keymap.set

vim.g.nvim_surround_no_normal_mappings = true
-- OLD @me "<C-q>" | "<C-q>q/Q"
KS("i", "<C-g>s", "<Plug>(nvim-surround-insert)", { desc = "Add a surrounding pair around the cursor (insert mode)", })
KS("i", "<C-g>S", "<Plug>(nvim-surround-insert-line)", { desc = "Add a surrounding pair around the cursor, on new lines (insert mode)", })
-- OLD @me "sa" OR "qa" DFL=ql
KS("n", "ys", "<Plug>(nvim-surround-normal)", { desc = "Add a surrounding pair around a motion (normal mode)", })
-- OLD @me "ql"
KS("n", "yss", "<Plug>(nvim-surround-normal-cur)", { desc = "Add a surrounding pair around the current line (normal mode)", })
KS("n", "yS", "<Plug>(nvim-surround-normal-line)", { desc = "Add a surrounding pair around a motion, on new lines (normal mode)", })
-- @me "ysS"
KS("n", "ySS", "<Plug>(nvim-surround-normal-cur-line)", { desc = "Add a surrounding pair around the current line, on new lines (normal mode)", })
-- OLD @me "q" DFL=S
KS("x", "S", "<Plug>(nvim-surround-visual)", { desc = "Add a surrounding pair around a visual selection", })
-- OLD @me "Q" DFL=gS
KS("x", "gS", "<Plug>(nvim-surround-visual-line)", { desc = "Add a surrounding pair around a visual selection, on new lines", })
-- OLD @me "sd" OR "qd"
KS("n", "ds", "<Plug>(nvim-surround-delete)", { desc = "Delete a surrounding pair", })
-- OLD @me "sr" OR "qr"
KS("n", "cs", "<Plug>(nvim-surround-change)", { desc = "Change a surrounding pair", })
KS("n", "cS", "<Plug>(nvim-surround-change-line)", { desc = "Change a surrounding pair, putting replacements on new lines", })

-- @me VIZ additional short-"hands"
KS("n", "q2", 'ysiw"', { desc = 'w|ord -> |"word"', remap = true })

-- FUT: language-specific
-- require("nvim-surround").buffer_setup({
--     surrounds = {
--         ["$"] = {
--             add = { "${", "}" },
--             find = "$%b{}",
--             delete = "^(..)().-(.)()$",
--             label = "${…}",
--         },
--     },
-- })

-- ALT:(TODO compare code): https://github.com/machakann/vim-sandwich
--   TALK: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
--   CMP: https://joereynoldsaudio.com/2020/01/22/vim-sandwich-is-better-than-surround.html
-- DEPR: (bloated) tpope/vim-surround
-- BAD: which-key preview has long delay due to nested <ys/ds> mappings
require("nvim-surround").setup {
  -- surrounds =
  -- aliases =       -- Defines aliases
  -- highlight =     -- Defines highlight behavior
  -- move_cursor =   -- Defines cursor behavior after a surround action
  -- indent_lines =  -- Defines line indentation behavior
  surrounds = {      -- Defines surround keys and behavior
    -- invalid_key_behavior = function()
    --   vim.api.nvim_err_writeln(
    --     "Error: Invalid character! Configure this message in " ..
    --     'require("nvim-surround").setup()'
    --   )
    -- end,
    -- pairs = {
      -- ["("] = { "( ", " )" },
      -- [")"] = { "(", ")" },
      -- ["{"] = { "{ ", " }" },
      -- ["}"] = { "{", "}" },
      -- ["<"] = { "< ", " >" },
      -- [">"] = { "<", ">" },
      -- ["["] = { "[ ", " ]" },
      -- ["]"] = { "[", "]" },

      ["“"] = { add = { '“', '”' } },
      ["«"] = { add = { '«', '»' } },
      ["‹"] = { add = { '‹', '›' } },

      ["$"] = { add = { '${', '}' } },
      ["@"] = { add = { '${', '[@]}' } },

      ["x"] = { add = { '⦅', '⦆' } },
      ["e"] = { add = { '⸢', '⸥' } },
      ["E"] = { add = { '⦏', '⦐' } },
      ["m"] = { add = { '【', '】' } },

      -- Define pairs based on function evaluations!
      ["i"] = { add = function()
        return {
          require("nvim-surround.utils").get_input(
            "Enter the left delimiter: "
          ),
          require("nvim-surround.utils").get_input(
            "Enter the right delimiter: "
          )
        }
      end },
      ["f"] = { add = function()
        return {
          require("nvim-surround.utils").get_input(
            "Enter the function name: "
          ) .. "(",
          ")"
        }
      end },

      -- ["a"] = {
      --   { "this", "has", "several", "lines" },
      --   "single line",
      -- },
      -- ["b"] = function()
      --   return {
      --     "hello",
      --     "world",
      --   }
      -- end,

      -- TODO: enable only for .puml
      --   ftplugin/plantuml.lua :: require("nvim-surround").buffer_setup {...}
      -- b = { "<b>", "</b>" },
      -- i = { "<i>", "</i>" },
      -- u = { "<u>", "</u>" },
    -- },
    -- separators = {
      -- ["'"] = { "'", "'" },
      -- ['"'] = { '"', '"' },
      -- ["`"] = { "`", "`" },

      [" "] = { add = { " ", " " } },
      ["*"] = { add = { "*", "*" } },
      ["_"] = { add = { "_", "_" } },
      ["~"] = { add = { "~", "~" } },
      ["·"] = { add = { '·', '·' } },
    -- },
    -- HTML = {
    --   ["t"] = "type", -- Change just the tag type
    --   ["T"] = "whole", -- Change the whole tag contents
    -- },
    aliases = {
      ["a"] = ">", -- Single character aliases apply everywhere
      ["b"] = ")",
      ["B"] = "}",
      ["r"] = "]",
      -- Table aliases only apply for changes/deletions
      ["q"] = { '"', "'", "`" }, -- Any quote character
      ["s"] = { ")", "]", "}", ">", "'", '"', "`" }, -- Any surrounding delimiter

      -- q = { "'", "'" },
      -- t = { "`", "`" },
      -- d = { '"', '"' },

      ["o"] = '·',
      ["1"] = '‹',
      ["2"] = '“',
      ["3"] = '«',
      ["Q"] = '«',
      ["4"] = '"${',
    },
  },
  -- highlight_motion = { -- Highlight before inserting/changing surrounds
  --   -- duration = false,
  --   duration = 0,
  -- }
}
