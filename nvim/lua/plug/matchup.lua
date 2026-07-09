
-- PERF: use C-STD "matchparen" inof slow vim-matchup CursorMoved
--   ~~ at least until you use "%" for the first time
vim.g.loaded_matchparen = 0
-- vim.g.matchparen_timeout = 20

-- vim.g.matchup_matchparen_offscreen = {'method': 'none'}
vim.g.matchup_matchparen_deferred = 1
-- vim.g.matchup_matchparen_enabled = 0


--NEED: move plugin into "opt"
--  FAIL: doesn't work from there
-- 1. Prevent default mappings so they don't break during late injection
-- vim.g.matchup_mappings_enabled = 0
-- local function load_matchup_on_the_fly()
--   if vim.g.loaded_matchup == nil then
--     vim.cmd("packadd vim-matchup")
--     vim.cmd("DoMatchParen")
--     -- Force the plugin to initialize its global runtime functions
--     vim.fn['matchup#init']()
--   end
-- end
--
-- -- 2. Create the raw user command
-- vim.api.nvim_create_user_command("MatchupEnable", function()
--   load_matchup_on_the_fly()
--   print("vim-matchup initialized!")
-- end, {})
--
-- -- 3. Map '%' to explicitly invoke the plugin's internal engine directly (No loops)
-- vim.keymap.set({ "n", "x", "o" }, "%", function()
--   load_matchup_on_the_fly()
--   -- Call the plugin's internal motion engine directly to guarantee jumping
--   vim.fn['matchup#motion#op']('%')
-- end, { desc = "Safely load and jump with matchup" })


-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = {"nou"}, -- replace with your filetypes
--   callback = {
--     function()
--       vim.b.matchup_matchparen_fallback = 0
--       vim.b.matchup_matchparen_enabled = 0
--     end,
--   },
-- })
