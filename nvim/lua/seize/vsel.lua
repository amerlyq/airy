-- ⌇⡢⡭⡱⠟
-- SRC: https://www.reddit.com/r/neovim/comments/p4u4zy/how_to_pass_visual_selection_range_to_lua_function/
-- FAIL: vmap <leader>foo :lua print(vim.inspect(getVisualSelection()))<Cr>
-- USAGE: vmap <leader>foo <Cmd>lua print(vim.inspect(getVisualSelection()))<Cr>
-- :h <Cmd>
-- ALT: /@/plugins/nvim/core/start/nvim-treesitter/lua/nvim-treesitter/incremental_selection.lua:23: function visual_selection_range()

local function getVisualSelection()
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2]
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')

  local sline, scol
  local eline, ecol
  if cline == vline then
    if ccol <= vcol then
      sline, scol = cline, ccol
      eline, ecol = vline, vcol
      scol = scol + 1
    else
      sline, scol = vline, vcol
      eline, ecol = cline, ccol
      ecol = ecol + 1
    end
  elseif cline < vline then
    sline, scol = cline, ccol
    eline, ecol = vline, vcol
    scol = scol + 1
  else
    sline, scol = vline, vcol
    eline, ecol = cline, ccol
    ecol = ecol + 1
  end

  if mode == "V" or mode == "CTRL-V" or mode == "\22" then
    scol = 1
    ecol = nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, sline - 1, eline, 0)
  if #lines == 0 then return end

  local startText, endText
  if #lines == 1 then
    startText = string.sub(lines[1], scol, ecol)
  else
    startText = string.sub(lines[1], scol)
    endText = string.sub(lines[#lines], 1, ecol)
  end

  local selection = { startText }
  if #lines > 2 then
    vim.list_extend(selection, vim.list_slice(lines, 2, #lines - 1))
  end
  table.insert(selection, endText)

  return selection
end

-- ALT: https://neovim.discourse.group/t/function-that-return-visually-selected-text/1601
-- ALSO:SEE: vim.highlight.on_yank
-- WAIT: https://github.com/neovim/neovim/pull/13896
local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

-- OLD: @me
-- vim.cmd [[
-- function! GetVisualSelection(...)
--   let [lnum1, col1] = getpos("'<")[1:2]
--   let [lnum2, col2] = getpos("'>")[1:2]
--   let lines = getline(lnum1, lnum2)
--   let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
--   let lines[0] = lines[0][col1 - 1:]
--   return a:0 >= 1 ? join(lines, a:1) : lines
-- endfunction
-- ]]

vim.cmd [[
fun! GetVisualSelection(...)
  return luaeval('require("seize.vsel")()')
endf
]]

return get_visual_selection
