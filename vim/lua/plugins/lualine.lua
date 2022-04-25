

-- vim.o.showtabline = 1

-- HACK:FAIL: hide tabline when only one tab/buffer is present
-- SRC: https://github.com/nvim-lualine/lualine.nvim/issues/395
-- FAIL: does not override
-- vim.cmd([[au OptionSet showtabline :set showtabline=1]])


--Set statusbar
--SRC: https://github.com/nvim-lualine/lualine.nvim
require('lualine').setup {
  options = {
    -- icons_enabled = false,
    theme = 'onedark',
    -- theme = 'molokai',
    component_separators = '|',
    section_separators = '',
    globalstatus = true,
  },
  sections = {
    lualine_a = {
      { 'mode',
        fmt = function(str)
          if str:find('-') == 2
          then return str:sub(3, 3)
          else return str:sub(1, 1)
          end
        end
      },
    },
    lualine_b = {'diagnostics'},  -- 'branch', 'diff'
    -- SRC: https://github.com/arkav/lualine-lsp-progress
    -- lualine_c = {'buffers'}, -- 'filename', 'lsp_progress'
    lualine_c = {
      { 'buffers',
        show_filename_only = false,
        buffers_color = {
          active = {fg='#abb2bf', bg='#073642'},
          inactive = {fg='#828997', bg='#2c323c'},
        },
      },
    },
    lualine_x = {'filetype'},  -- 'tabs', 'encoding', 'fileformat'
  },
  tabline = {
    -- lualine_c = {
    --   { 'buffers',
    --     show_filename_only = false,
    --     -- hide_filename_extension = false,   -- Hide filename extension when set to true.
    --     buffers_color = {
    --       active = {fg='#abb2bf', bg='#073642'},
    --       inactive = {fg='#828997', bg='#2c323c'},
    --     },
    --   },
    -- },
    -- lualine_x = {'tabs'},
  },
}

-- vim.highlight.create('lualine_c_buffers_active', {guifg='#abb2bf', guibg='#2c323c'}, true)
-- vim.highlight.create('lualine_c_buffers_inactive', {guifg='#828997', guibg='#072f3b'}, true)
