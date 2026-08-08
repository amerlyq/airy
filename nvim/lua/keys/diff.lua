
-- TRY: axkirillov/unified.nvim: an inline, unified diff viewer for neovim ⌇⡪⡶⢡⡴
--   https://github.com/axkirillov/unified.nvim
-- ALT? mini.diff documentation – MINI ⌇⡪⡶⢡⡚
--   https://nvim-mini.org/mini.nvim/doc/mini-diff.html

local function is_change(line)
  return line:match("^[+-][^+-]") ~= nil
end

local function is_file_header(line)
  return line:match("^diff %-%-git ") ~= nil or line:match("^Index: ") ~= nil
end

local function is_commit_boundary(line)
  return line:match("^$") ~= nil or line:match("^#") ~= nil
end

local function jump_hunk(direction)
  local buf = 0
  local count = vim.api.nvim_buf_line_count(buf)
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local line = current + direction

  while line >= 1 and line <= count do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

    if text:match("^@@") then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end

    line = line + direction
  end
end

local function jump_change_group(direction)
  local buf = 0
  local count = vim.api.nvim_buf_line_count(buf)
  local current = vim.api.nvim_win_get_cursor(0)[1]

  local line = current + direction

  while line >= 1 and line <= count do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

    if is_change(text) then
      local previous = line > 1
        and vim.api.nvim_buf_get_lines(buf, line - 2, line - 1, false)[1]
        or ""

      -- Only stop at the beginning of a consecutive group.
      if not is_change(previous) then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        return
      end
    end

    line = line + direction
  end
end

local function jump_file(direction)
  local buf = 0
  local count = vim.api.nvim_buf_line_count(buf)
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local line = current + direction

  while line >= 1 and line <= count do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

    if is_file_header(text) then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end

    line = line + direction
  end
end

local function jump_commit_boundary(direction)
  local buf = 0
  local count = vim.api.nvim_buf_line_count(buf)
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local line = current + direction

  while line >= 1 and line <= count do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

    if is_commit_boundary(text) then
      local previous = line > 1
        and vim.api.nvim_buf_get_lines(buf, line - 2, line - 1, false)[1]
        or ""
      local next = line < count
        and vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]
        or ""

      -- Treat consecutive comments/blank lines as one boundary.  In either
      -- direction, land on the first line of that boundary block.
      if not is_commit_boundary(previous) then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        return
      elseif direction < 0 and is_commit_boundary(next) then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        return
      end
    end

    line = line + direction
  end
end


vim.api.nvim_create_autocmd("FileType", {
  pattern = "diff",
  callback = function(args)
    local map = vim.keymap.set
    map("n", "]c", function() jump_change_group(1) end, { buffer = true, desc = "chg↑ (diff)" })
    map("n", "[c", function() jump_change_group(-1) end, { buffer = true, desc = "chg↓ (diff)" })
    map("n", "]s", function() jump_hunk(1) end, { buffer = true, desc = "hunk↑ (diff)" })
    map("n", "[s", function() jump_hunk(-1) end, { buffer = true, desc = "hunk↓ (diff)" })
    map("n", "]f", function() jump_file(1) end, { buffer = true, desc = "file↑ (diff)" })
    map("n", "[f", function() jump_file(-1) end, { buffer = true, desc = "file↓ (diff)" })
    map("n", "]]", function() jump_commit_boundary(1) end, { buffer = true, desc = "commit↑ (diff)" })
    map("n", "[[", function() jump_commit_boundary(-1) end, { buffer = true, desc = "commit↓ (diff)" })
  end,
})
