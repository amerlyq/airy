
require 'plug.cmp_' -- +luasnip
require 'plug.gitsigns'

require 'plug.surround'

require('mini.move').setup({  --- ALT※⡤⣪⡒⡮
  mappings = {
    left  = '<S-left>',
    right = '<S-right>',
    down  = '<S-down>',
    up    = '<S-up>',

    line_left  = '<S-left>',
    line_right = '<S-right>',
    line_down  = '<S-down>',
    line_up    = '<S-up>',
  }
})

-- OLD:ALT:
--   https://github.com/kana/vim-operator-replace
--   https://github.com/thinca/vim-quickrun
require('mini.operators').setup({
  evaluate = { -- Evaluate text and replace with output
    prefix = 'g<BS>',  -- DFL='g='
    func = nil,  -- Function which does the evaluation
  },
  exchange = { -- Exchange text regions
    prefix = '', -- DFL='gx'  -- OBSOL: https://github.com/gbprod/substitute.nvim
    reindent_linewise = true,  -- Whether to reindent new text to match previous indent
  },
  multiply = { -- Multiply (duplicate) text
    prefix = 'gC',  -- DFL='gm'
    func = nil,  -- Function which can modify text before multiplying
  },
  replace = { -- Replace text with register
    prefix = 'gr',  -- OR: 'cr'
    reindent_linewise = true,
  },
  sort = {
    prefix = ',S',
    func = nil
  }
})


--Enable Comment.nvim
-- https://github.com/numToStr/Comment.nvim
--   ALT: mini.comment
-- require('Comment').setup()
require('nvim_comment').setup {
  -- HACK: pull "commentstring" based on HEREDOC language
  -- hook = function()
  --   if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
  --     require("ts_context_commentstring.internal").update_commentstring()
  --   end
  -- end
}


-- DISABLED:(errors-out): no updates from 2022
-- require('spellsitter').setup {
--   -- Whether enabled, can be a list of filetypes, e.g. {'python', 'lua'}
--   enable = true,
-- }


require('legendary').setup()

--SUM: dif menu for input(LSP_rename) and select(LSP_code_actions)
-- EXPL: https://www.reddit.com/r/neovim/comments/r7yd8w/dressingnvim_customize_your_vimui_in_neovim_06/hn3gcdy/?context=3
require('dressing').setup()


-- DISABLED: I'm pissed off by the need to delete braces all the time
--   TEMP: work w/o this plugin to understand what I will be missing,
--     and if my suffering is mitigating any bigger suffering
-- MORE: https://github.com/windwp/nvim-autopairs
-- require('nvim-autopairs').setup {
--   disable_filetype = { "c" },  -- COS irritating brackets everywhere,fixing wrong ones is longer than typing
--   enable_check_bracket_line = false,
--   map_c_h = true,
--   check_ts = true,
-- }
-- -- If you want insert `(` after select function or method item
-- local cmp_autopairs = require('nvim-autopairs.completion.cmp')
-- local handlers = require('nvim-autopairs.completion.handlers')
-- local cmp = require('cmp')
-- local kinds = cmp.lsp.CompletionItemKind
-- cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done {
--   -- map_char = { tex = '' },
--   filetypes = {
--     lisp = {
--       ["("] = {
--         kind = { kinds.Function, kinds.Method },
--         handler = handlers.lisp
--       },
--       -- FIXME: disable macro-prefix
--       ["'"] = false,
--     }
--   }
-- })


require('pretty-fold').setup()
require('fold-preview').setup()


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


-- SRC: https://github.com/ghillb/cybu.nvim
-- TALK: https://www.reddit.com/r/neovim/comments/uu2rfn/cybunvim_v10_a_plugin_to_cycle_buffers_with/
-- require("cybu").setup()
require("cybu").setup {
  display_time = 450,
  style = {
    devicons = {
      enabled = false,
    },
  }
}


-- SRC: https://github.com/gbprod/substitute.nvim
-- LIOR Exchange text: cx{motion} on first, then cx{motion} on other.
-- OLD: https://github.com/tommcdo/vim-exchange
--   OLD:ALT: https://github.com/osyo-manga/vim-operator-swap
--   ALT:(reuse): mini.operators.exchange
-- WARN: keymap overshadows "leap"
require('substitute').setup {}
local xcg = require('substitute.exchange')
local K = require('keys.bind').K
K("x", "X", xcg.visual)
K("n", "cx", xcg.operator)
K("n", "cxc", xcg.line)
K("n", "cxx", xcg.cancel)


--SRC: https://github.com/ggandor/leap.nvim
-- require('leap').set_default_keymaps()
-- -- Define equivalence classes for brackets and quotes, in addition to the default whitespace group.
-- require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
-- -- Override some old defaults - use backspace instead of tab (see issue #165).
-- require('leap').opts.special_keys.prev_target = '<backspace>'
-- require('leap').opts.special_keys.prev_group = '<backspace>'
require('leap').setup {}
-- Use the traversal keys to repeat the previous motion without explicitly invoking Leap.
require('leap.user').set_repeat_keys('<enter>', '<backspace>')


-- SRC: https://github.com/RaafatTurki/hex.nvim
-- require('hex').setup()
