--[Treesitter configuration]
--%SUMMARY: Highlight, edit, and navigate code using a fast incremental parsing library

--SRC: https://github.com/nvim-treesitter/nvim-treesitter
--SRC: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--ALSO:VIZ: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins

--CFG:    :TSInstall bash c cpp cmake commonlisp diff json lua python
--MAINT:  :TSUpdate
--DEBUG:  :TSModuleInfo


require('nvim-treesitter').setup {
  -- Directory to install parsers and queries to
  install_dir = vim.fn.stdpath('data') .. '/site',
}


-- VIZ: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
-- asm, awk, bitbake, css, csv, devicetree, dockerfile, dot, doxygen, fennel, fidl,
-- git_config, git_rebase, gitcommit, gnuplot, go, gpg, haskell, html, http, ini,
-- java, javascript, jq, kotlin, latex, leo, llvm, make, markdown, markdown_inline,
-- mermaid, meson, muttrc, nasm, nginx, ninja, objdump, perl, php, powershell,
-- printf, r, readline, regex, ruby, scss, sql, ssh_config, strace, tcl, tmux,
-- toml, tsv, udev, vim, yaml
local ensureInstalled = {
  "awk",
  "bash",
  "c",
  "cmake",
  "commonlisp",
  "cpp",
  "diff",
  "dockerfile",
  "html",
  "ini",
  "jq",
  "json",
  "lua",
  -- "make",
  "markdown",
  "ninja",
  "perl",
  "printf",
  "python",
  "regex",
  "rst",
  "strace",
  "toml",
  "v",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

local alreadyInstalled = require("nvim-treesitter.config").get_installed()

local parsersToInstall = vim.iter(ensureInstalled)
  :filter(function(parser) return not vim.tbl_contains(alreadyInstalled, parser) end)
  :totable()

-- WTF: downloads and compiles each time
--   FIXED: "paci tree-sitter-cli" OR (!ubuntu=20.04) by !cargo ※⡨⣝⢯⠖
-- SEE> :TSLog -- it doesn't seem to move .so into $XDG_DATA_HOME/nvim/site/parser
--    debug(install/ini): Moving /home/user/.cache/nvim/tree-sitter-ini-tmp/tree-sitter-ini-... to /home/user/.cache/nvim/tree-sitter-ini/...
--   :lua print(vim.fn.stdpath('data'))
-- DEBUG> :checkhealth nvim-treesitter
--   ERROR Nvim-treesitter requires Neovim 0.11.0 or later.
--   ERROR tree-sitter CLI not found
--     $ npm install -g tree-sitter-cli
require("nvim-treesitter").install(parsersToInstall) -- OR: }):wait(300000) -- wait max. 5 minutes


-- ALT:HACK: enable for all supported
-- vim.api.nvim_create_autocmd("FileType", {
--   callback = function(details)
--     local bufnr = details.buf
--     if not pcall(vim.treesitter.start, bufnr) then -- try to start treesitter which enables syntax highlighting
--           return -- Exit if treesitter was unable to start
--     end
--     vim.bo[bufnr].syntax = "on" -- Use regex based syntax-highlighting as fallback as some plugins might need it
--     vim.wo.foldlevel = 99
--     vim.wo.foldmethod = "expr"
--     vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- Use treesitter for folds
--     vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- Use treesitter for indentation
--   end,
-- })
-- OR:
-- local parsersInstalled = require("nvim-treesitter.config").get_installed('parsers')
-- for _, parser in pairs(parsersInstalled) do
--   local filetypes = vim.treesitter.language.get_filetypes(parser)
--   vim.api.nvim_create_autocmd({ "FileType" }, {
--     pattern = filetypes,
--     callback = function()
--       -- TODO https://www.reddit.com/r/neovim/comments/1kuj9xm/has_anyone_successfully_switched_to_the_new/
--       -- DEBUG: lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)
--       -- REF: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
--       -- MAYBE? if not pcall(vim.treesitter.start) then return end
--       vim.treesitter.start()
--       vim.o.foldmethod = "expr"  -- <RQ
--       vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--       vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--     end,
--   })
-- end


-- [_] FIXME:USE: rainbow-delimiters.nvim
--   rainbow = {
--     enable = true,
--     -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
--     extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
--     max_file_lines = nil, -- Do not enable for files with more than n lines, int
--     -- colors = {}, -- table of hex strings
--     -- termcolors = {} -- table of colour name strings
--   },

--   --SRC: https://github.com/JoosepAlviste/nvim-ts-context-commentstring
--   --  USAGE: automatically changes "commentstring" based on HEREDOC language
--   -- WARN:
--   -- context_commentstring nvim-treesitter module is deprecated, use require('ts_context_commentstring').setup {} and set vim.g.skip_ts_context_commentstring_module = true to speed up loading instead.
--   -- This feature will be removed in ts_context_commentstring version in the future (see https://github.com/JoosepAlviste/nvim-ts-context-commentstring/issues/82 for more info)
--   -- context_commentstring = {
--   --   enable = true,
--   --   config = {
--   --     cpp = '// %s'
--   --   }
--   -- },

-- [_] FIXME:USE: https://github.com/daliusd/incr.nvim
--   -- DONE: inof 'terryma/vim-expand-region'
--   incremental_selection = {
--     enable = true,
--     keymaps = {
--       init_selection = '+',
--       node_incremental = '+',
--       node_decremental = '-',
--       scope_incremental = '_',
--     },
--   },

--   indent = {
--     enable = true,
--   },

--   -- NOTE:(custom queries): ./after/queries/<filetype>/textobjects.scm
--   -- REF: https://github.com/nvim-treesitter/nvim-treesitter#adding-queries
--   textobjects = {
--     swap = {
--       enable = true,
--       -- OR: https://github.com/AndrewRadev/sideways.vim
--       -- OR: https://github.com/machakann/vim-swap
--       swap_previous = { ["ga"] = "@parameter.inner" },
--       swap_next = { ["gA"] = "@parameter.inner" },
--     },
--     lsp_interop = {
--       enable = true,
--       border = "none",
--       peek_definition_code = {
--         ["g<Bslash>d"] = "@function.outer",
--         ["g<Bslash>D"] = "@class.outer",
--       },
--     },
--     select = {
--       enable = true,
--       lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
--       keymaps = {
--         -- You can use the capture groups defined in textobjects.scm
--         ['af'] = '@function.outer',
--         ['if'] = '@function.inner',
--         ['ac'] = '@class.outer',
--         ['ic'] = '@class.inner',
--       },
--     },


-- FIXME:USE: https://github.com/aaronik/treewalker.nvim
--     move = {
--       enable = true,
--       set_jumps = true, -- whether to set jumps in the jumplist
--       goto_next_start = {
--         [']]'] = '@function.outer',
--         [']}'] = '@class.outer',
--       },
--       goto_next_end = {
--         [']['] = '@function.outer',
--         [']{'] = '@class.outer',
--       },
--       goto_previous_start = {
--         ['[['] = '@function.outer',
--         ['[{'] = '@class.outer',
--       },
--       goto_previous_end = {
--         ['[]'] = '@function.outer',
--         ['[}'] = '@class.outer',
--       },
--     },
--   },
--   --SRC: https://github.com/andymass/vim-matchup
--   matchup = {
--     enable = true,
--     -- disable = { "c", "ruby" },
--     -- disable_virtual_text = true,
--   },
-- }
