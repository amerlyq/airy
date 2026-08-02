-- ALT:(TODO compare code): https://github.com/machakann/vim-sandwich
--   TALK: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
--   CMP: https://joereynoldsaudio.com/2020/01/22/vim-sandwich-is-better-than-surround.html
-- DEPR: (bloated) tpope/vim-surround
-- BAD: which-key preview has long delay due to nested <ys/ds> mappings

-- OR? local K = require'keys.bind'.K
local KS = vim.keymap.set

vim.g.nvim_surround_no_normal_mappings = true

-- OLD @me "<C-q>" | "<C-q>q/Q"
KS("i", "<C-g>s", "<Plug>(nvim-surround-insert)", { desc = "Add a surrounding pair around the cursor (insert mode)", })
KS("i", "<C-g>S", "<Plug>(nvim-surround-insert-line)", { desc = "Add a surrounding pair around the cursor, on new lines (insert mode)", })
-- OLD @me "sa" OR "qa" DFL=ql|ys
KS("n", "ys", "<Plug>(nvim-surround-normal)", { desc = "Add a surrounding pair around a motion (normal mode)", })
-- OLD @me "ql"
KS("n", "yss", "<Plug>(nvim-surround-normal-cur)", { desc = "Add a surrounding pair around the current line (normal mode)", })
KS("n", "yS", "<Plug>(nvim-surround-normal-line)", { desc = "Add a surrounding pair around a motion, on new lines (normal mode)", })
-- @me "ysS"
KS("n", "ySS", "<Plug>(nvim-surround-normal-cur-line)", { desc = "Add a surrounding pair around the current line, on new lines (normal mode)", })
-- OLD @me "q" DFL=S
KS("x", "q", "<Plug>(nvim-surround-visual)", { desc = "Add a surrounding pair around a visual selection", })
-- OLD @me "Q" DFL=gS
KS("x", "Q", "<Plug>(nvim-surround-visual-line)", { desc = "Add a surrounding pair around a visual selection, on new lines", })
-- OLD @me "sd" OR "qd"
-- ALSO:TODO: "dsS" -- delete outermost "dss"
KS("n", "ds", "<Plug>(nvim-surround-delete)", { desc = "Delete a surrounding pair", })
-- OLD @me "sr" OR "qr"
KS("n", "cs", "<Plug>(nvim-surround-change)", { desc = "Change a surrounding pair", })
KS("n", "cS", "<Plug>(nvim-surround-change-line)", { desc = "Change a surrounding pair, putting replacements on new lines", })


-- @me VIZ additional short-"hands"

-- Word-based quoting (reversed by frecency)
-- DEV: "n" "ql/qL" -- add quotes to trimmed line or blockwise
-- DEV: "x" "qw.." -- add quotes to each word in selection
KS("n", "qw", 'ysiW', { desc = 'W|ORD -> |?WORD?', remap = true })
KS("n", "qW", 'ysiw', { desc = 'w|ord -> |?word?', remap = true })
-- KS("n", "ql", 'ysil', { desc = '| line | -> | ?line? |', remap = true })

-- Spaces as special quotes
KS("n", "q ", 'ysiw ', { desc = 'w|ord -> | word ', remap = true })
-- KS("x", "q ", 'q ', { desc = 'w|ord -> | word ', remap = true })

-- Add quotes on qq
KS("n", "qq", 'ysiw"', { desc = 'w|ord -> |"word"', remap = true })
KS("n", 'q"', 'ysiw"', { desc = 'w|ord -> |"word"', remap = true })
KS("n", "q'", "ysiw'", { desc = "w|ord -> |'word'", remap = true })

KS("x", "qq", 'q"',    { desc = 'w|ord -> |"word"', remap = true })

KS("n", "qQ", 'ysiwQ', { desc = 'w|ord -> |“word”', remap = true })
KS("n", "qA", 'ysiwA', { desc = 'w|ord -> |«word»', remap = true })
KS("n", "q1", 'ysiwa', { desc = 'w|ord -> |‹word›', remap = true })
KS("n", "q<", 'ysiw<', { desc = 'w|ord -> |<word>', remap = true })
KS("n", "q>", 'ysiw>', { desc = 'w|ord -> |>word<', remap = true })

-- Sigils for bash
KS("n", "q4", 'ysiw4', { desc = 'w|ord -> |"${word}"', remap = true })
KS("n", "q3", 'ysiw3', { desc = 'w|ord -> |"$(word)"', remap = true })
KS("n", "q2", 'ysiw2', { desc = 'w|ord -> |"${word[@]}"', remap = true })
KS("n", "q$", 'ysiw$', { desc = 'w|ord -> |${word}', remap = true })
KS("n", "q&", 'ysiw&', { desc = 'w|ord -> |$(word)', remap = true })
KS("n", "q@", 'ysiw@', { desc = 'w|ord -> |${word[@]}', remap = true })


require("nvim-surround").setup {
  move_cursor = "sticky",  -- VIZ=false|"begin"|"sticky"
  highlight = { duration = 20 },  -- flash b4 ins/chg surr
  surrounds = {
    -- STD::INFO:(invalid_key_behavior): any other single char repeats /[ *_~·].../
    -- ["'"] = { "'", "'" },
    -- ['"'] = { '"', '"' },
    -- ["`"] = { "`", "`" },
    -- ["("] = { "( ", " )" },
    -- [")"] = { "(", ")" },
    -- ["{"] = { "{ ", " }" },
    -- ["}"] = { "{", "}" },
    -- ["<"] = { "< ", " >" },
    -- [">"] = { "<", ">" },
    -- ["["] = { "[ ", " ]" },
    -- ["]"] = { "[", "]" },
    -- ["i"] = input(delimiter ?...?)
    -- ["f"] = input(function(...))
    -- ["t/T"] = input(HTML tag <?>...</?>)
      -- ["B"] = { '<b>', '</b>' },  -- ALT? remap "qtb" -> add HTML tag <b>...</b>
      -- ["I"] = { '<i>', '</i>' },
      -- ["U"] = { '<u>', '</u>' },
      -- TODO: enable only for .puml
      --   ftplugin/plantuml.lua :: require("nvim-surround").buffer_setup {...}
    -- TRY? Define pairs based on function evaluations!
    -- ["a"] = { { "this", "has", "several", "lines" }, "single line", },
    -- ["b"] = function() return { "hello", "world" } end,

    -- ["<"] = { ">", "<" }, -- <CHG: overrule
    -- TRY:HACK? still add '"' on 'q' (in parallel to alias)
    ["q"] = { add = { '"', '"' } },

    ["$"] = { add = { '${', '}' } },
    ["@"] = { add = { '${', '[@]}' } },
    ["&"] = { add = { '$(', ')' } },
    ["4"] = { add = { '"${', '}"' } },
    ["3"] = { add = { '"$(', ')"' } },
    ["2"] = { add = { '"${', '[@]}"' } },

    ["Q"] = { '“', '”' },
    ["A"] = { '«', '»' },
    ["a"] = { '‹', '›' },

    ["x"] = { '⦅', '⦆' },
    ["E"] = { '⸢', '⸥' },
    ["X"] = { '⦏', '⦐' },
    ["M"] = { '【', '】' },
  },
  aliases = {
    -- ["a"] = ">", -- Single character aliases apply everywhere
    ["b"] = ")",
    ["c"] = "}",
    ["r"] = "]",

    ["0"] = ")",
    ["9"] = "}",
    ["8"] = "*",
    -- ["7"] = '“',
    ["6"] = '“',
    -- ["5"] = '%',
    -- ["4"] = '"${',
    -- ["3"] = '«',
    -- ["2"] = '"',
    ["1"] = '‹',

    -- ["t"] = '`',
    -- ["d"] = '"',
    ["o"] = '·',
    ["Q"] = '«',

    -- Table aliases only apply for changes/deletions
    ["q"] = { '"', "'", "`" }, -- Any quote character
    ["p"] = { ")", "]", "}", ">" }, -- Any bracket character
    ["s"] = { ")", "]", "}", ">", "'", '"', "`" }, -- Any surrounding delimiter
  },
}


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
