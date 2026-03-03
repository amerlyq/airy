-- Diagnostic keymaps for LSP
local K = require'keys.bind'.K

-- REF: `:h vim.diagnostic.*` for documentation on any of the below functions
local D = vim.diagnostic

K('n', '[d', D.goto_prev)
K('n', ']d', D.goto_next)
K('n', ',tf', D.open_float)
-- K('n', ',tx', D.hide)
-- K('n', ',tX', D.disable)


-- local function diagnostic_format(diagnostic)
--   local source = diagnostic.source or "LSP"
--   local code = diagnostic.code and string.format("[%s]", diagnostic.code) or ""
--   return string.format("%s: %s %s", source, diagnostic.message, code)
-- end
--
-- K('n', ',q', function() D.setloclist {
--   format = diagnostic_format,
--   title = "Buffer Diagnostics",
-- } end, "Diag: Annotated Loclist")
--
-- K('n', ',Q', function() D.setqflist {
--   format = diagnostic_format,
--   title = "LSP Diagnostics",
-- } end, "Diag: Annotated Quickfix")


-- local function set_annotated_qf(is_loclist)
--     local func = is_loclist and vim.diagnostic.setloclist or vim.diagnostic.setqflist
--     func({
--         title = is_loclist and "Buffer Diagnostics" or "LSP Diagnostics",
--         -- Use on_list to physically rewrite the 'text' displayed in Quickfix
--         on_list = function(options)
--             for _, item in ipairs(options.items) do
--                 -- We have to find the diagnostic associated with this item
--                 -- Or simpler: use the existing 'text' and prepend the source
--                 -- Note: diagnostics are usually stored in the user_data or
--                 -- we can match the message.
--                 item.text = string.format("[%s] %s", item.user_data and item.user_data.source or "LSP", item.text)
--             end
--             vim.fn.setqflist(options.items, 'r')
--             if not is_loclist then vim.cmd("copen") else vim.cmd("lopen") end
--         end
--     })
-- end
-- K('n', ',q', function() set_annotated_qf(true) end, "Diag: Annotated Loclist")
-- K('n', ',Q', function() set_annotated_qf(false) end, "Diag: Annotated Quickfix")


-- DEBUG: :lua =vim.diagnostic.get(0)[1].source
local function diagnostic_format(diagnostic)
  local source = diagnostic.source or "LSP"
  local code = diagnostic.code and string.format(" [%s]", diagnostic.code) or ""
  -- This creates the EXACT string that will appear in the Quickfix window
  return string.format("%s: %s%s", source, diagnostic.message, code)
end

local function set_custom_diag_list(is_loclist)
  -- 0 for current buffer (loclist), nil for all buffers (quickfix)
  local scope = is_loclist and 0 or nil
  local diagnostics = vim.diagnostic.get(scope)
  local qf_items = {}

  for _, d in ipairs(diagnostics) do
    table.insert(qf_items, {
      bufnr = d.bufnr,
      lnum = d.lnum + 1,
      col = d.col + 1,
      -- This is the key: we manually set the 'text' field BQF reads
      text = diagnostic_format(d),
      type = d.severity == 1 and "E" or "W",
    })
  end

  if is_loclist then
    vim.fn.setloclist(0, qf_items, 'r')
    vim.cmd("lopen")
  else
    vim.fn.setqflist(qf_items, 'r')
    vim.cmd("copen")
  end
end

-- Your requested mappings
K('n', ',q', function() set_custom_diag_list(true) end, "Diag: Annotated Loclist")
K('n', ',Q', function() set_custom_diag_list(false) end, "Diag: Annotated Quickfix")


vim.diagnostic.config({
  virtual_text = {
    source = "always",  -- Shows tool name in the line text
  },
  -- float = {
  --   source = "always",  -- Shows tool name in the hover window
  -- },
  signs = true,
  underline = true,
  update_in_insert = false,
  -- This part ensures the source is added to the message string
  -- when diagnostics are converted to quickfix items
  severity_sort = true,
})
