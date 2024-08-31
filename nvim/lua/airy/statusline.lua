--%RELOAD:FAIL: require('plenary.reload').reload_module('airy.statusline', true)
--%RELOAD:ALT: luafile $MYLUA/airy/statusline.lua
--%WARN:NEED: 'set mouse=a' -- otherwise clicking won't work in some modes
local o, g = vim.opt, vim.g
--OBSOL: https://github.com/nvim-lualine/lualine.nvim
-- ALSO https://github.com/kdheepak/tabline.nvim
-- https://github.com/romgrk/barbar.nvim
-- https://github.com/nanozuki/tabby.nvim
--    


-- o.statusline = '%<%f %h%m%r%=%y %-10.(%4l,%c%V%) %P'
-- statusline=%{%v:lua.require'lualine'.statusline()%}
-- o.statusline = '%!v:lua.airy_statusline()'
o.tabline = '%!v:lua.airy_statusline()'


-- HACK: prevent reset on reload/luafile
if vim.fn.has('vim_starting') == 1 then

  -- HACK:FAIL: hide tabline when only one tab/buffer is present
  -- SRC: https://github.com/nvim-lualine/lualine.nvim/issues/395
  -- FAIL:(does not override): vim.cmd([[au OptionSet showtabline :set showtabline=1]])
  -- o.showtabline = 1
  o.showtabline = 1


  -- o.laststatus = 3  -- global statusline for multiple buffers
  o.laststatus = 0 -- hide statusline for single buffer
end

--DEBUG:
--:echo luaeval('vim.api.nvim_list_bufs()')
--:echo luaeval('vim.api.nvim_list_bufs() > 1 and 3 or 0')
--:echo luaeval('vim.api.nvim_list_bufs():filter(vim.api.nvim_buf_is_loaded)')
local buflist = vim.api.nvim_list_bufs
local bufgetopt = vim.api.nvim_buf_get_option
local bufgetname = vim.api.nvim_buf_get_name
local bufcurrent = vim.api.nvim_get_current_buf
-- local bufloaded = vim.api.nvim_buf_is_loaded

vim.cmd([[
fun! AirySwitchBuffer(bufnr, mouseclicks, mousebutton, modifiers)
  execute ":buffer " . a:bufnr
endf
]])

local function hide_statusline(t)
  local nr = 0
  for _, b in ipairs(buflist()) do
    if b == t.buf or bufgetopt(b, 'buflisted') then
      if not (b == t.buf and t.event == 'BufDelete') then
        nr = nr + 1
        if nr > 1 then break end
      end
    end
  end
  local v = nr > 1 and 2 or 1
  if o.showtabline ~= v then
    o.showtabline = v
  end
  -- local v = nr > 1 and 3 or 0
  -- if o.laststatus ~= v then
  --   o.laststatus = v
  -- end
end

vim.api.nvim_create_autocmd({ 'VimEnter', 'BufAdd', 'BufDelete' }, {
  desc = "(auto) hide statusbar for single buffer",
  -- ALT: command = "{x->if &laststatus!=x|let &laststatus=x|en}(len(getbufinfo({'buflisted':1})) <= 1 ? 0 : 3)"
  callback = hide_statusline
})

--NOTE: after diagnostics cleared -- hide statusbar manually <,tl>
vim.api.nvim_create_autocmd({ 'DiagnosticChanged' }, {
  desc = "(auto) open statusbar on new diagnostics",
  callback = function()
    local diags = vim.diagnostic.get(0)
    if #diags > 0 then
      o.showtabline = 2
    end
  end
})


-- ALSO: https://github.com/arkav/lualine-lsp-progress
local function lsp()
  local D, L = vim.diagnostic, vim.diagnostic.severity
  -- ALT:PERF? query once, count myself
  -- for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
  --   count[diagnostic.severity] = count[diagnostic.severity] + 1
  -- end
  local spec = {
    [" %#DiagnosticError# "] = vim.tbl_count(D.get(0, { severity = L.ERROR })),
    [" %#DiagnosticWarn# "] = vim.tbl_count(D.get(0, { severity = L.WARN })),
    [" %#DiagnosticHint# "] = vim.tbl_count(D.get(0, { severity = L.INFO })),
    [" %#DiagnosticInfo# "] = vim.tbl_count(D.get(0, { severity = L.HINT })),
  }
  local s = ""
  for k, v in pairs(spec) do
    if v ~= 0 then
      s = s .. k .. v
    end
  end
  return s
end

local function filetype()
  local ft, fenc, ff = vim.bo.filetype, vim.bo.fileencoding, vim.bo.fileformat
  local s = "%#TabLineFill# ." .. ft -- :upper()  -- string.format("%s ", ft)
  if fenc ~= 'utf-8' then s = s .. "%#Error#[" .. fenc .. "]" end
  if ff ~= 'unix' then s = s .. "%#Error#[" .. ff .. "]" end
  return s .. " "
end

local function delcommonpfxsfx(s, t)
  for i = 1, math.min(#s, #t) do
    if s:byte(i) ~= t:byte(i) then
      if i > 2 then
        s = "…" .. s:sub(i)
        t = "…" .. t:sub(i)
      end
      break
    end
  end
  for j = 1, math.min(#s, #t) do
    if s:byte(-j) ~= t:byte(-j) then
      if j > 2 then
        s = s:sub(1, -j) .. "…"
        t = t:sub(1, -j) .. "…"
      end
      break
    end
  end
  return s, t
end

local function clickable(bufid, label)
  return "%" .. bufid .. "@AirySwitchBuffer@" .. label .. "%X"
end

local function buffers()
  local s = ""
  local prevnm = ""
  local cur = bufcurrent()
  for _, b in ipairs(buflist()) do -- OR: tabpagebuflist()
    if bufgetopt(b, 'buflisted') then
      local fnm = bufgetname(b)
      -- local bt = bufgetopt(b, 'buftype')
      -- local ft = bufgetopt(b, 'filetype')
      local mod = bufgetopt(b, 'modified')
      -- FIXME: don't shorten current buffer
      local hl = (b == cur) and "%#TabLineSel#" or "%#TabLine#"
      local nm = "[No Name]"
      if fnm then
        -- MAYBE: only prefix parent dir if name matches ~typical~ names
        --   like docs "\u+.nou" or keys 20\d\d-.*
        -- ALT:BET: only add prefix if there are same bufnames (or similar for e.g. keys/dates)
        nm = vim.fn.fnamemodify(fnm, ':p:h:t') .. "/" .. vim.fn.fnamemodify(fnm, ':t')
      end
      -- NEED: modify previous entry -- insert !hi=underline group at beg/end pos of reuse
      local snm = delcommonpfxsfx(nm, prevnm)
      local sfx = (mod and '+' or '') -- '●'
      s = s .. clickable(b, hl .. " " .. snm .. sfx .. " ")
      prevnm = nm
    end
  end
  return s
end

function airy_statusline()
  -- TODO: enable "lsp" only for .py .lua
  return table.concat {
    buffers(),
    -- "%<%f %h%m%r",
    "%#TabLine#",
    "%=",
    lsp(),
    filetype(),
    -- 'tabs'
    -- ' %-10.(%4l,%c%V%) %P',
  }
end
