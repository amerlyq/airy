
-- local highlight_groups = {
--   Identifier = {bg=red, fg=black, style='bold'},
--   -- SomethingElse = function(self) return {fg=self.Identifier.fg, bg=self.Function.bg} end,
-- }

---@private
function M.create(higroup, hi_info, default)
  local options = {}
  -- TODO: Add validation
  for k, v in pairs(hi_info) do
    table.insert(options, string.format("%s=%s", k, v))
  end
  vim.cmd(string.format([[highlight %s %s %s]], default and "default" or "", higroup, table.concat(options, " ")))
end

---@private
function M.link(higroup, link_to, force)
  vim.cmd(string.format([[highlight%s link %s %s]], force and "!" or " default", higroup, link_to))
end
