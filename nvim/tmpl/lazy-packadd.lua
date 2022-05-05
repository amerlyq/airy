--⌇⡢⡲⣜⣯ lazy-packadd
--%SUMMARY: annotated boilerplates to use for my lazy-loaded plugins

--[[
  FAIL? "packadd" may add "autocmd Filetype" but they won't be triggered
    FAIL? other autocmd (triggered before) -- won't trigger events in freshly loaded plugin

  NOTE: based on SRC of "dein" -- all *global* autocmds are triggered manually to trigger fresh plugin
    BAD: this results in double-execution of global autocommands (and therefore flickering BUG)

  BET: grep plugins SRC and explicitly trigger all found autocmds in their respective augroups
  OR: even copy-paster code from those :autocmd which don't have :augroup to prevent global disaster
    ex: I don't want to trigger all events in ALL groups for ft=python again
      ⦅vim⦆ vim.api.nvim_exec_autocmds({'FileType'}, {group='', buffer=0, pattern='python', modeline=false})

  [⡢⡲⣁⣹] TODO: grep all event names $ /@/airy/nvim/exe/grep-autocmd
    "autocmd BufEnter <buffer=%d> ++once lua require'lspconfig'[%q]._setup_buffer(%d,%d)",
    string.format('autocmd BufHidden,BufLeave <buffer> ++once lua pcall(vim.api.nvim_win_close, %d, true)', win_id)
--]]


----[:/init.lua]----
--(boilerplate:trigger)
--ALT: nvim/after/ftplugin/python.lua
--ALT:BET? on VimEnter -> if ft==python then load
vim.api.nvim_create_autocmd('FileType', {
  -- group = api.nvim_create_augroup('LazyPackadd', {}),
  desc = "(Lazy) packadd LSP and TreeSitter",
  once = true,
  pattern = 'python',  -- vim.bo.filetype
  -- nested = true,
  callback = function()
    require 'lazy.lsp'
  end
})



----[:/lua/lazy/lsp.lua]----
--(boilerplate:header)
--NOTE:(sfx=!): only add to &rtp for init.vim access, don't source plugin/*
vim.cmd [[packadd! nvim-lspconfig]]


-- CFG: plugin configuration / user preferences
require('lspconfig')["pylsp"].setup {
  -- ...
}

--(boilerplate:footer)
-- FAIL: I don't want to trigger all events in ALL groups for ft=python again
-- vim.api.nvim_exec_autocmds({'FileType'}, {group='', buffer=0, pattern='python', modeline=false})
--HACK: copy-pasted "autocmd FileType" to avoid triggering all events for python in ALL plugins
--  NOTE: run only once -- for the current buffer, which triggered "packadd", afterwards STD autocmd will do same
require'lspconfig'["pylsp"].manager.try_add()

-- NOTE:(vim_starting=1): if launched by opening .py file
--   >> defer till startup next step "plugin/*" auto sourcing
if vim.fn.has('vim_starting') == 0 then
  --WARN:(packadd again): usually plugin/* should be sourced AFTER vimrc, not before
  --  NICE: no duplicate &rtp entries added
  vim.cmd [[packadd nvim-lspconfig]]
end
