
-- EXPL: Add indentation guides even on blank lines
-- SRC: https://github.com/lukas-reineke/indent-blankline.nvim
-- FIXED: visual block selection uses "reverse" but plugin does not support that
-- FIXME: dunno how to "hi! link"
--   TRY: vim.highlight.link("TelescopeMatching", "Constant", true)
-- FUTURE:BET: reuse short func from there inof large buggy plugin below
--    ~/.cache/vim/dein/repos/github.com/nathanaelkane/vim-indent-guides/autoload/indent_guides.vim
-- OR:TRY: ⌇⡢⡥⢛⠵ https://github.com/glepnir/indent-guides.nvim


-- SEE:(blend): more virt_text display options by bfredl · Pull Request #14065 · neovim/neovim ⌇⡢⡥⢘⡞
--   https://github.com/neovim/neovim/pull/14065


--## rainbow-delimiters.nvim integration
local highlights = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}
local hooks = require "ibl.hooks"
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
    -- OR:
    -- local colors = { "#E06C75", "#E5C07B", "#61AFEF", "#D19A66", "#98C379", "#C678DD", "#56B6C2" }
    -- for i, color in ipairs(colors) do
    --     vim.api.nvim_set_hl(0, "ScopeColor" .. i, { fg = color })
    -- end
end)
-- vim.g.rainbow_delimiters = { highlight = highlights }
vim.g.rainbow_delimiters.highlight = highlights  -- @me (don't override whole cfg)


-- DISABLED:(permanent/distracting):
-- require("ibl").setup { indent = { highlight = highlights } }

-- DISABLED:(doesn't work for python, as it has no {} brackets):
--   MAYBE: enable based on 'ft'
-- require("ibl").setup { scope = { highlight = highlights } }
-- hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

-- FIXED? dynamic scope colors based on indent level
require("ibl").setup {
    indent = {
        char = "┊",
        -- char = "│",
        -- highlight = highlights,
    },
    scope = {
        enabled = true,
        -- char = "│",
        highlight = highlights,
    }
}
hooks.register(hooks.type.SCOPE_HIGHLIGHT, function(tick, bufnr, scope, scope_index)
    -- Check if a valid Treesitter scope node exists
    if not scope then return 1 end

    -- Get the starting row of the current active scope node
    local start_row, _, _, _ = scope:range()

    -- Fetch the exact line text from the buffer to determine its actual indentation
    local line_text = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    if not line_text then return 1 end

    -- Count leading whitespace characters to compute the indentation level
    local leading_spaces = string.match(line_text, "^%s*") or ""
    local space_count = #leading_spaces

    -- Handle standard tab width configs dynamically (defaults to shiftwidth or tabstop)
    local sw = vim.bo[bufnr].shiftwidth
    if sw == 0 then sw = vim.bo[bufnr].tabstop end
    if sw == 0 then sw = 4 end -- Fallback protection

    -- Convert total spaces to an indent depth index (1, 2, 3...)
    local level = math.floor(space_count / sw) + 1

    -- Map cleanly back into your 7 highlights array
    return ((level - 1) % 7) + 1
end)



--## ALT: Background color indentation guides
-- local highlight = {
--     "CursorColumn",
--     "Whitespace",
-- }
-- require("ibl").setup {
--     indent = { highlight = highlight, char = "" },
--     whitespace = {
--         highlight = highlight,
--         remove_blankline_trail = false,
--     },
--     scope = { enabled = false },
-- }


-- OLD:FIXED:WKRND: visually select indented space
--   SRC: https://github.com/lukas-reineke/indent-blankline.nvim/issues/328
-- vim.cmd([[hi! Visual cterm=None ctermfg=102 ctermbg=23 gui=None guifg=#586e75 guibg=#002b36 guisp=none ]])
-- vim.highlight.create('Visual', {cterm=None, ctermfg=102, ctermbg=242,
--   gui=None, guifg='#586e75', guibg='#002b36', guisp=None}, true)
-- vim.cmd([[hi! Visual guibg=#586e75 gui=None guifg=#002b36 ]])
-- vim.cmd([[hi! Visual cterm=None ctermbg=242 guibg=#839496 gui=None,nocombine guifg=#002b36 ]])
