-- ALT:(new): https://github.com/comfysage/artio.nvim
-- OR: Mini.pick! (with the mini-extra plufin) -- with preview in tab inof floating
-- ALT: https://github.com/alexpasmantier/tv.nvim
-- ALT: https://github.com/dmtrKovalenko/fff

-- Snacks.nvim Configuration (Replaces Telescope)
-- UI Layout and Custom Keybindings Strategy
local snacks = require("snacks")

snacks.setup({
  picker = {
    -- Matches your old requirement: vertical layout, prompt on top, clear visual list
    layout = {
      cycle = true,
      layout = {
        box = "vertical",
        backdrop = false,
        row = 2,
        width = 0.90,
        height = 0.90,
        { win = "input", height = 1, border = "rounded", title = "{title} {live}" },
        { win = "list", border = "rounded" },
        { win = "preview", title = "{preview}", border = "rounded" },
      },
    },
    -- Default UI behavior mirroring your Telescope overrides
    ui_select = true, -- Hook up standard vim.ui.select choices to snacks!
    win = {
      input = {
        keys = {
          -- Mirrors your Telescope input mode overrides
          ["<C-u>"] = false,                   -- Restores standard clear line
          ["<C-d>"] = { "close", mode = "i" }, -- Close picker on Ctrl+D
          ["<C-j>"] = { "list_down", mode = { "i", "n" } },
          ["<C-k>"] = { "list_up", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["q"] = "close", -- Standardized normal mode close key
        },
      },
    },
  },
})

-- Keymap Helper Function (Matches your old 'Kn' structure perfectly)
local Kn = function(lhs, fn, desc)
  vim.keymap.set("n", lhs, fn, { silent = true, desc = desc })
end

-- ==========================================
-- Native Keymaps Mapping (Old Telescope -> New Snacks)
-- ==========================================

-- Core Picker & Registry Lists
Kn("<Tab><CR>",    function() snacks.picker.pickers() end,          "Snacks.pickers (Built-ins)")
Kn("<Tab><Space>", function() snacks.picker.buffers() end,          "Snacks.buffers")
Kn("<Tab><Tab>",   function() snacks.picker.resume() end,           "Snacks.resume")
Kn("<Tab>?",       function() snacks.picker.recent() end,           "Snacks.recent (Oldfiles)")

-- Search & Buffer Browsing
Kn("<Tab>b", function() snacks.picker.lines() end,                  "Snacks.lines (Fuzzy buffer find)")
Kn("<Tab>c", function() snacks.picker.tags() end,                   "Snacks.tags")
Kn("<Tab>d", function() snacks.picker.diagnostics() end,            "Snacks.diagnostics")
-- Old config disabled the previewer here; snacks makes toggleable preview simple:
Kn("<Tab>f", function() snacks.picker.files({ preview = false }) end, "Snacks.files (No preview)")

-- Git Integration
Kn("<Tab>g", function() snacks.picker.git_status() end,             "Snacks.git_status")
Kn("<Tab>G", function() snacks.picker.git_log() end,                "Snacks.git_log (Commits)")

-- Navigation, Metadata, and LSP
Kn("<Tab>h", function() snacks.picker.help() end,                   "Snacks.help")
Kn("<Tab>j", function() snacks.picker.jumps() end,                  "Snacks.jumps")
Kn("<Tab>l", function() snacks.picker.lsp_symbols() end,            "Snacks.lsp_symbols")
Kn("<Tab>m", function() snacks.picker.recent() end,                 "Snacks.recent")
Kn("<Tab>q", function() snacks.picker.qflist() end,                 "Snacks.qflist")

-- In Snacks, search results are strictly stable, synchronous-looking, and async-fast.
-- We no longer need separate parallel/stable implementations because it doesn't flicker!
Kn("<Tab>r", function() snacks.picker.grep() end,                   "Snacks.grep (Stable)")
Kn("<Tab>R", function() snacks.picker.grep() end,                   "Snacks.grep (Parallel)")
Kn("<Tab>k", function() snacks.picker.keymaps() end,                "Snacks.keymaps (Tagstack replacement)")

-- Alternative Search Shortcuts (, Shortcuts)
Kn(",as", function() snacks.picker.grep() end,                      "Snacks.grep")
Kn(",rs", function() snacks.picker.grep() end,                      "Snacks.grep")
Kn(",.",  function() snacks.picker.grep_word() end,                 "Snacks.grep_word (Under cursor)")
Kn(",*",  function() snacks.picker.grep_word() end,                 "Snacks.grep_word (Under cursor)")
