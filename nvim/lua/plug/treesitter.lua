--[Treesitter configuration]
--%SUMMARY: Highlight, edit, and navigate code using a fast incremental parsing library

--SRC: https://github.com/nvim-treesitter/nvim-treesitter
--SRC: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--ALSO:VIZ: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins

--CFG:    :TSInstall python
--MAINT:  :TSUpdate
--DEBUG:  :TSModuleInfo

require('nvim-treesitter.configs').setup {
  -- ensure_installed = { "c", "lua", "rust" },
  ensure_installed = { "python", "lua" },
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  --SRC: https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  --  USAGE: automatically changes "commentstring" based on HEREDOC language
  context_commentstring = {
    enable = true,
    -- config = {
    --   css = '// %s'
    -- }
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
  -- NOTE:(custom queries): ./after/queries/<filetype>/textobjects.scm
  -- REF: https://github.com/nvim-treesitter/nvim-treesitter#adding-queries
  textobjects = {
    swap = {
      enable = true,
      swap_next = { ["ga"] = "@parameter.inner" },
      swap_previous = { ["gA"] = "@parameter.inner" },
    },
    lsp_interop = {
      enable = true,
      border = "none",
      peek_definition_code = {
        ["<Bslash>df"] = "@function.outer",
        ["<Bslash>dF"] = "@class.outer",
      },
    },
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
  },
}
