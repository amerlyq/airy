--[Treesitter configuration]
--%SUMMARY: Highlight, edit, and navigate code using a fast incremental parsing library

--SRC: https://github.com/nvim-treesitter/nvim-treesitter
--SRC: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--ALSO:VIZ: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins

--CFG:    :TSInstall bash c cpp cmake commonlisp diff json lua python
--MAINT:  :TSUpdate
--DEBUG:  :TSModuleInfo

require('nvim-treesitter.configs').setup {
  ensure_installed = {
    "python", "lua", "bash",
    "c", "cpp", "cmake", "commonlisp",
    "diff", "json", "rst",
    "v", "vimdoc", "xml"
  },
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
    -- colors = {}, -- table of hex strings
    -- termcolors = {} -- table of colour name strings
  },
  --SRC: https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  --  USAGE: automatically changes "commentstring" based on HEREDOC language
  -- WARN:
  -- context_commentstring nvim-treesitter module is deprecated, use require('ts_context_commentstring').setup {} and set vim.g.skip_ts_context_commentstring_module = true to speed up loading instead.
  -- This feature will be removed in ts_context_commentstring version in the future (see https://github.com/JoosepAlviste/nvim-ts-context-commentstring/issues/82 for more info)
  -- context_commentstring = {
  --   enable = true,
  --   config = {
  --     cpp = '// %s'
  --   }
  -- },
  -- DONE: inof 'terryma/vim-expand-region'
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '+',
      node_incremental = '+',
      node_decremental = '-',
      scope_incremental = '_',
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
      -- OR: https://github.com/AndrewRadev/sideways.vim
      -- OR: https://github.com/machakann/vim-swap
      swap_previous = { ["ga"] = "@parameter.inner" },
      swap_next = { ["gA"] = "@parameter.inner" },
    },
    lsp_interop = {
      enable = true,
      border = "none",
      peek_definition_code = {
        ["g<Bslash>d"] = "@function.outer",
        ["g<Bslash>D"] = "@class.outer",
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
        [']]'] = '@function.outer',
        [']}'] = '@class.outer',
      },
      goto_next_end = {
        [']['] = '@function.outer',
        [']{'] = '@class.outer',
      },
      goto_previous_start = {
        ['[['] = '@function.outer',
        ['[{'] = '@class.outer',
      },
      goto_previous_end = {
        ['[]'] = '@function.outer',
        ['[}'] = '@class.outer',
      },
    },
  },
  --SRC: https://github.com/andymass/vim-matchup
  matchup = {
    enable = true,
    -- disable = { "c", "ruby" },
    -- disable_virtual_text = true,
  },
}
