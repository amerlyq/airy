-- ALT:(TODO compare code): https://github.com/machakann/vim-sandwich
--   TALK: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
--   CMP: https://joereynoldsaudio.com/2020/01/22/vim-sandwich-is-better-than-surround.html
-- DEPR: (bloated) tpope/vim-surround
require("nvim-surround").setup {
  keymaps = {
    -- ALSO:TODO: use <C-q> for insert mappings
    -- insert = "q", -- qa | ys
    -- insert_line = "Q", -- ql | yss
    -- visual = "q",
    -- delete = "ds", -- qd
    -- change = "cs", -- qr
    insert = "<C-g>s",
    insert_line = "<C-g>S",
    normal = "ys",
    normal_cur = "yss",
    normal_line = "yS",
    normal_cur_line = "ysS",
    visual = "q",  -- DFL=S
    visual_line = "Q",  -- DFL=gS
    delete = "ds",
    change = "cs",
  },
  surrounds = {
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

local KG = vim.api.nvim_set_keymap
-- local K = require('keys.bind').K
KG("n", "q2", 'ysiw"', {})
