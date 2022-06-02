--%DEBUG: :echo getmatches()
local M = {}

function M.register()
  local spec = require 'notches.spec'

  local ns_id = 0 -- FAIL: vim.api.nvim_create_namespace('notches')
  local nvim_set_hl = vim.api.nvim_set_hl
  local hlID = vim.fn.hlID

  for hlgrp, attrs in pairs(spec.highlights) do
    --CHECK:PERF: ALT: clear hi ns/group
    if hlID(hlgrp) == 0 then
      nvim_set_hl(ns_id, hlgrp, attrs)
    end
  end

  local matchadd = vim.fn.matchadd
  -- local rpfx = '\\v%(^|.*!|\\A@1<=)'
  -- local rsfx = '%(!.*|[:?*.=~]+|\\A@=|$)'
  local rpfx = '\\v<'
  local rsfx = '%(>|[:?=])'

  vim.fn.clearmatches()
  for hlgrp, vrgx in pairs(spec.patterns) do
    matchadd(hlgrp, rpfx .. vrgx .. rsfx, -1)
  end
end

function M.iabbrev()
  local spec = require 'notches.spec'
  local enxkb = 'qwertyuiop asdfghjkl zxcvbnm QWERTYUIOP ASDFGHJKL ZXCVBNM'
  local ruxkb = 'йцукенгшщз фывапролд ячсмить йцукенгшщз фывапролд ячсмить'
  for _, vrgx in pairs(spec.patterns) do
    for notch in string.gmatch(vrgx:gsub('[\\%%()]', ''), "([^|]+)") do
      -- TODO: both lower() and UPPER() case should translate to same UPPER iabbr
      -- :iab[breviate] [<expr>] [<buffer>] {lhs} {rhs}
      local ru = vim.fn.tr(notch:gsub('[-.:;]', ''), enxkb, ruxkb)
      local cmd = string.format('iab <buffer> %s %s', ru, notch)
      -- print(cmd)
      vim.cmd(cmd)
    end
  end
end

function M.autocmd()
  local augrp = vim.api.nvim_create_augroup('Notches', { clear = true })

  vim.api.nvim_create_autocmd({ 'WinEnter' }, { -- , 'Syntax', 'ColorScheme'
    desc = "(flower) register notches everywhere",
    group = augrp,
    callback = M.register
  })

  vim.api.nvim_create_autocmd('FileType', {
    desc = "(flower) register notches ru-en iabbr for .nou",
    pattern = 'nou',
    group = augrp,
    callback = M.iabbrev
  })
end

return M
