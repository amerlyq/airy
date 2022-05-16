require 'plug.cmp' -- +luasnip
require 'plug.gitsigns'

require 'plug.surround'

--Enable Comment.nvim
-- https://github.com/numToStr/Comment.nvim
-- require('Comment').setup()
require('nvim_comment').setup {
  -- HACK: pull "commentstring" based on HEREDOC language
  -- hook = function()
  --   if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
  --     require("ts_context_commentstring.internal").update_commentstring()
  --   end
  -- end
}

--OFF:TUT: https://github.com/ggandor/leap.nvim
--LIOR: s|S char1 char2 <space>? (<space>|<tab>)* label?
require('leap').set_default_keymaps()
-- vim.cmd [[ autocmd ColorScheme * lua require('leap').init_highlight(true) ]]

require('spellsitter').setup {
  -- Whether enabled, can be a list of filetypes, e.g. {'python', 'lua'}
  enable = true,
}


require('legendary').setup()

--SUM: dif menu for input(LSP_rename) and select(LSP_code_actions)
-- EXPL: https://www.reddit.com/r/neovim/comments/r7yd8w/dressingnvim_customize_your_vimui_in_neovim_06/hn3gcdy/?context=3
require('dressing').setup()


-- MORE: https://github.com/windwp/nvim-autopairs
require('nvim-autopairs').setup {
  -- enable_check_bracket_line = false,
  map_c_h = true,
  check_ts = true,
}
-- If you want insert `(` after select function or method item
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))


require 'plug.telescope'

-- BUG:WTF: :verb map v -> "viÞ <Nop>" waiting pause
-- SRC: https://github.com/folke/which-key.nvim
-- ALT: telescope.actions.which_key()
local presets = require("which-key.plugins.presets")
presets.operators[">"] = nil
presets.operators["<lt>"] = nil
require("which-key").setup {
  spelling = {
    enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
    suggestions = 20, -- how many suggestions should be shown in the list?
  },
}
