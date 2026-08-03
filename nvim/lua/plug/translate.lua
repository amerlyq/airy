
-- SRC:※⡪⡰⣂⡺ https://github.com/askfiy/smart-translate.nvim
require("smart-translate").setup({
  engine = "google",   -- VIZ: "google", "bing", (API-keys: "deepl", or "baidu")
  default = {
    cmds = {
      target = "en",
      handle = "replace",  -- VIZ: "float" or "register" for clipboard
    },
  },
  fallback = {
    ru = "en",
    en = "ru",
    ua = "en",
  },
  -- Clean, scannable UI layout
  window = {
    border = "rounded", -- Options: "none", "single", "double", "rounded", "solid", "shadow"
    width = 0.6,        -- 60% of editor width
    height = 0.4,       -- 40% of editor height
  }
})

-- Evaluate a phrase or highlighted idiom
vim.keymap.set("v", "<leader>tr", "<cmd>TranslateVisual<CR>", { silent = true, desc = "Translate and replace" })
vim.keymap.set("n", "<leader>tr", "<cmd>Translate<CR>", { silent = true, desc = "Translate and replace" })
vim.keymap.set("v", "<leader>tR", "<cmd>TranslateVisual --handle=float<CR>", { desc = "Translate in float-wnd" })
vim.keymap.set("v", "<leader>ty", "<cmd>TranslateVisual --handle=register<CR>", { desc = "Translate to clipboard" })
