
--Set colorscheme
vim.o.termguicolors = true

vim.cmd 'colorscheme airy'            -- PERF=1.8ms
-- vim.cmd 'colorscheme airy_viml'    -- PERF=2ms
-- vim.g.material_style = "deep ocean"
-- vim.cmd 'colorscheme material'     -- PERF=8ms
-- vim.cmd 'colorscheme soluarized'   -- PERF=12ms
-- vim.cmd [[colorscheme solarized]]  -- PERF=19ms

-- NICE: https://github.com/NLKNguyen/papercolor-theme

--SRC: https://github.com/folke/tokyonight.nvim ⌇⡢⡮⢮⠥
-- vim.g.tokyonight_style = "night"
-- vim.g.tokyonight_italic_functions = true
-- vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
-- Change the "hint" color to the "orange" color, and make the "error" color bright red
-- vim.g.tokyonight_colors = { hint = "orange", error = "#ff0000" }
-- vim.cmd [[colorscheme tokyonight]]


--SRC: https://github.com/ishan9299/nvim-solarized-lua.git
--ALT: 'shaunsingh/solarized.nvim'
-- vim.cmd [[colorscheme solarized]]
-- vim.g.solarized_disable_background = true
-- require('solarized').set()
