-------------------------------------------------------------------------------
-- DIFFT.NVIM (The Structural Viewer)
-- SRC: https://github.com/ahkohd/difft.nvim
-- DEP=!difftastic, plenary.nvim
-------------------------------------------------------------------------------

-- Only create the command if the plugin was actually found in your rtp
local status_ok, difft = pcall(require, "difft")
if status_ok then
  -- BAD: default ones are uncomfortably bright
  local groups = {
    DifftAdd    = "DiffAdd",
    DifftDelete = "DiffDelete",
    -- DifftChange = "DiffText",   -- Changed logic/nodes
    -- DifftInfo   = "Identifier", -- Metadata/Headers
    -- DifftDim    = "Comment",    -- Unchanged context code
  }
  for difft_group, nvim_group in pairs(groups) do
    vim.api.nvim_set_hl(0, difft_group, { link = nvim_group, force = true })
  end

  difft.setup({
      -- Explicitly tell it to ignore all whitespace in the underlying git call
      command = "GIT_EXTERNAL_DIFF='difft --color=always --width=180' git diff -w",
      -- layout = "float", -- Centered floating window is best for quick checks
      window = {
          width = 0.9,
          height = 0.8,
          border = "rounded",
      },
      keymaps = {
          next = "]", -- Navigate between file changes
          prev = "[",
          close = "q",
      }
  })
  -- "<leader>d", function() if Difft.is_visible() then Difft.hide() else Difft.diff() end end, desc = "Toggle Difft",

  vim.api.nvim_create_user_command('Difft', function()
      Difft.diff()
  end, { bar = true, desc = "Open Difftastic structural diff" })
end

-------------------------------------------------------------------------------
-- DIFFMANTIC.NVIM (The Semantic Highlighter)
-- SRC: https://github.com/HarshK97/diffmantic.nvim
-------------------------------------------------------------------------------
-- Note: As of early 2026, diffmantic is lean on options.
-- It relies heavily on your existing Tree-sitter parsers.
require('diffmantic').setup({
    -- Internal defaults are usually best, but ensure it's initialized
})

-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function()
--         -- Only trigger if it's a git-tracked file and not too huge
--         local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
--         if stats and stats.size < 500000 then -- 500KB limit
--             -- Check if the file has changes before starting the plugin
--             local has_changes = vim.fn.system("git status --porcelain " .. vim.fn.expand("%")) ~= ""
--             if has_changes then
--                 -- Schedule the spawn so it doesn't block UI startup
--                 vim.schedule(function()
--                     vim.cmd("Diffmantic")
--                 end)
--             end
--         end
--     end,
-- })

local function diffmantic_git_head()
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then return end

    -- 1. Create a temp file path (e.g., /tmp/filename.py.HEAD)
    local extension = vim.fn.expand("%:e")
    local temp_file = vim.fn.tempname() .. "." .. extension

    -- 2. Use git show to dump the HEAD version into the temp file
    -- We use 'git ls-files --full-name' to ensure we get the correct repo path
    local relative_path = vim.fn.systemlist("git ls-files --full-name " .. current_file)[1]
    if not relative_path or relative_path == "" then
        print("File not tracked by git")
        return
    end

    os.execute("git show HEAD:" .. relative_path .. " > " .. temp_file)

    -- 3. Run Diffmantic on the two files
    -- Format: Diffmantic <file1> <file2>
    vim.cmd("Diffmantic " .. temp_file .. " " .. current_file)

    -- Optional: Clean up the temp file when Neovim exits
    vim.api.nvim_create_autocmd("VimLeave", {
        callback = function() os.remove(temp_file) end
    })
end

-- Map it to something quick
vim.keymap.set('n', '\\gh', diffmantic_git_head, { desc = "Semantic Diff vs HEAD" })


-------------------------------------------------------------------------------
-- CUSTOM FUGITIVE INTEGRATION
-------------------------------------------------------------------------------
-- This adds 'gs' (Git Structural) and 'gm' (Git mantic) to your Fugitive window
vim.api.nvim_create_autocmd("FileType", {
    pattern = "fugitive",
    callback = function()
        local opts = { buffer = true, remap = false }
        -- gt: Structural diff (Great for checking if a refactor changed logic)
        vim.keymap.set("n", "gt", "<cmd>Difft<CR>", opts)
        -- gm: Semantic diff (Great for staying in the buffer)
        vim.keymap.set("n", "gm", "<cmd>Diffmantic<CR>", opts)
    end,
})

-- Global shortcuts for when you aren't in Fugitive
vim.keymap.set("n", "\\gt", "<cmd>Difft<CR>", { desc = "Git Structural Diff" })
vim.keymap.set("n", "\\gm", "<cmd>Diffmantic<CR>", { desc = "Git Semantic Diff" })


-------------------------------------------------------------------------------
-- deeper integration
-- SRC: https://github.com/jecaro/fugitive-difftool.nvim
-------------------------------------------------------------------------------
-- local fd = require('fugitive-difftool')
--
-- -- 1. Create User Commands for navigation
-- -- These allow you to browse the quickfix list populated by :Git difftool
-- vim.api.nvim_create_user_command('Gcn', fd.git_cn, {})    -- Next change
-- vim.api.nvim_create_user_command('Gcp', fd.git_cp, {})    -- Previous change
-- vim.api.nvim_create_user_command('Gcfir', fd.git_cfir, {}) -- First change
-- vim.api.nvim_create_user_command('Gcla', fd.git_cla, {})   -- Last change
--
-- -- 2. Smart Bindings for Fugitive Status Window
-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = "fugitive",
--     callback = function()
--         local opts = { buffer = true, silent = true }
--
--         -- Press 'gr' (Git Review) to diff against main/master
--         -- Using --name-status makes the quickfix list clean (one entry per file)
--         vim.keymap.set("n", "gr", ":Git! difftool --name-status main...<CR>", opts)
--
--         -- Use bracket navigation to jump through the files in the quickfix list
--         vim.keymap.set("n", "]q", "<cmd>Gcn<CR>", opts)
--         vim.keymap.set("n", "[q", "<cmd>Gcp<CR>", opts)
--     end,
-- })
