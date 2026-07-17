local K = require'keys.bind'.K

K('n', ',/', function()
  local s = "\\V" .. vim.fn.getreg('+')
  vim.fn.histadd("/", s)
  vim.fn.setreg("/", s, "c")
  vim.cmd('noau normal! n')
end)

-- local function GetLineBookmark()
-- end
-- K('n', '<Leader>y', "<Cmd>lua GetLineBookmark(v:count, getline('.'))<CR>")
-- K('n', '<Leader>gy', "<Cmd>let &showtabline=(&stal<2?2:1)<CR>")
-- :xnoremap <CR> <Cmd>echom getregion(getpos('v'), getpos('.'), #{ type: mode() })<CR>

K('nv', '<Leader>y', "<Cmd>call setreg('+', getreg('%').':'.line('.'), 'l')<CR>")
K('n', '<Leader>Y', function()
  local path = vim.fn.getreg("%")
  if path:sub(1,1) ~= "/" then
    path = "//" .. path
  else
    -- TBD: if path -ef any_of(/d/*) then path = /d/xxx/ .. path:sub(...)
  end
  local lnum = vim.fn.line(".")
  local line = vim.fn.getline("."):gsub("^%s+", ""):gsub("%s+$", "")
  local bmrk = path .. ":" .. lnum .. ":" .. "\n  " .. line
  vim.fn.setreg("+", bmrk, "l")
end)


--ALT: :lua local m = {}; vim.fn.bufnr('%'):lines(0, -1):map(function(l) for w in l:gmatch("your-pattern") do table.insert(m, w) end end); vim.fn.setreg('+', table.concat(m, '\n'))
--TBD: \M to copy whole lines
-- vim.keymap.set('n', '<leader>m', function()
--   -- Get your last active search pattern
--   local search_pattern = vim.fn.getreg('/')
--   if search_pattern == "" then
--     print("No active search pattern found.")
--     return
--   end
--
--   local matches = {}
--   -- Get all line text from current buffer
--   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
--
--   for _, line in ipairs(lines) do
--     local start_idx = 1
--     while true do
--       -- vim.fn.matchstrpos uses native Vim regex engine for 100% accuracy
--       -- It finds the match, start index, and end index
--       local match_info = vim.fn.matchstrpos(line, search_pattern, start_idx - 1)
--       local match_text = match_info[1]
--       local s_byte = match_info[2]
--       local e_byte = match_info[3]
--
--       -- Break loop if no more matches exist on this line
--       if match_text == "" or s_byte == -1 then
--         break
--       end
--
--       table.insert(matches, match_text)
--       -- Move index forward past current match to avoid infinite loop
--       start_idx = e_byte + 1
--     end
--   end
--
--   if #matches > 0 then
--     -- Join matches with newlines and push directly to system clipboard
--     vim.fn.setreg('+', table.concat(matches, "\n"))
--     print("Copied " .. #matches .. " exact regex matches to clipboard!")
--   else
--     print("No exact matches found in buffer text.")
--   end
-- end, { desc = "Extract exact text matching last search" })


local function get_search_pattern()
  local search_pattern = vim.fn.getreg('/')
  if search_pattern == "" then
    print("No active search pattern found.")
    return nil
  end
  return search_pattern
end

-- Returns {lines, is_partial, col_start, col_end} for the last visual selection,
-- or nil if not in/after a visual selection context.
local function get_range_lines(is_visual)
  local line1, line2, col1, col2

  if is_visual then
    -- '< and '> marks are only set after leaving visual mode, so use them
    -- via a normal-mode escape trick isn't needed here: keymap runs with
    -- range already resolved by the caller (see keymap.set below).
    line1 = vim.fn.line("'<")
    line2 = vim.fn.line("'>")
    col1 = vim.fn.col("'<")
    col2 = vim.fn.col("'>")
  else
    line1 = 1
    line2 = vim.fn.line('$')
  end

  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)

  local mode = vim.fn.visualmode()
  if is_visual and mode == 'v' and #lines > 0 then
    -- charwise: trim partial first/last line to the actual selection.
    -- col() is 1-based byte index; sub() is 1-based inclusive, so no
    -- further adjustment needed for the start, but col2 may exceed the
    -- line's length when selection ends at/past EOL (common with $), so clamp it.
    lines[#lines] = lines[#lines]:sub(1, math.min(col2, #lines[#lines]))
    lines[1] = lines[1]:sub(col1)
  end
  -- linewise ('V') and blockwise (CTRL-V) selections: use full lines as-is,
  -- consistent with how registers 'V and block-visual yanks behave for our purpose.

  return lines
end

local function copy_matches(is_visual)
  local search_pattern = get_search_pattern()
  if not search_pattern then return end

  local lines = get_range_lines(is_visual)
  local matches = {}
  for _, line in ipairs(lines) do
    local start_idx = 0
    while true do
      local match_info = vim.fn.matchstrpos(line, search_pattern, start_idx)
      local match_text, s_byte, e_byte = match_info[1], match_info[2], match_info[3]
      if s_byte == -1 then break end
      table.insert(matches, match_text)
      start_idx = (e_byte > s_byte) and e_byte or (e_byte + 1)
    end
  end

  if #matches > 0 then
    vim.fn.setreg('+', table.concat(matches, "\n"))
    print("Copied " .. #matches .. " exact regex matches to clipboard!")
  else
    print("No exact matches found in range.")
  end
end

local function copy_matching_lines(is_visual)
  local search_pattern = get_search_pattern()
  if not search_pattern then return end

  local lines = get_range_lines(is_visual)
  local matched_lines = {}
  for _, line in ipairs(lines) do
    if vim.fn.match(line, search_pattern) ~= -1 then
      table.insert(matched_lines, line)
    end
  end

  if #matched_lines > 0 then
    vim.fn.setreg('+', table.concat(matched_lines, "\n"))
    print("Copied " .. #matched_lines .. " matching lines to clipboard!")
  else
    print("No matching lines found in range.")
  end
end

vim.keymap.set('n', '<leader>m', function() copy_matches(false) end,
  { desc = "Extract exact text matching last search (buffer)" })
vim.keymap.set('v', '<leader>m', function() copy_matches(true) end,
  { desc = "Extract exact text matching last search (selection)" })

vim.keymap.set('n', '<leader>M', function() copy_matching_lines(false) end,
  { desc = "Copy whole lines matching last search (buffer)" })
vim.keymap.set('v', '<leader>M', function() copy_matching_lines(true) end,
  { desc = "Copy whole lines matching last search (selection)" })

--- OR: resolve visual-mark correctly
-- line("'<")/col("'<") inside a v-mode keymap callback: these marks update
--   once Vim processes the visual-to-normal transition, which normally happens
--   on <Esc> before the mapping's RHS runs for a :<C-u>-style command — but a
--   Lua function callback bound directly in v mode may run before that
--   transition completes, meaning '</'> could reflect the previous selection,
--   not the current one. This is the one part of my answer that's inference from
--   documented mode-switching semantics, not confirmed behavior.
-- Safer, well-established pattern: bind to :<C-u>lua ...<CR> explicitly so the
--   marks are guaranteed set, or read vim.fn.getpos("v") and vim.fn.getpos(".")
--   directly while still in visual mode.
--- NEED: global functions
-- function CopyMatches(is_visual)
--   -- same body as before
-- end
-- function CopyMatchingLines(is_visual)
--   -- same body as before
-- end
-- vim.keymap.set('v', '<leader>m', ":<C-u>lua CopyMatches(true)<CR>",
--   { desc = "Extract exact text matching last search (selection)" })
-- vim.keymap.set('v', '<leader>M', ":<C-u>lua CopyMatchingLines(true)<CR>",
--   { desc = "Copy whole lines matching last search (selection)" })
-- vim.keymap.set('n', '<leader>m', function() CopyMatches(false) end,
--   { desc = "Extract exact text matching last search (buffer)" })
-- vim.keymap.set('n', '<leader>M', function() CopyMatchingLines(false) end,
--   { desc = "Copy whole lines matching last search (buffer)" })
