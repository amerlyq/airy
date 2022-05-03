local o, g = vim.opt, vim.g

--DEBUG:
--:echo luaeval('vim.api.nvim_list_bufs()')
--:echo luaeval('vim.api.nvim_list_bufs() > 1 and 3 or 0')
--:echo luaeval('vim.api.nvim_list_bufs():filter(vim.api.nvim_buf_is_loaded)')
-- o.laststatus = 0  -- hide statusline for single buffer
-- o.laststatus = 3  -- global statusline for multiple buffers
local buflist, bufloaded = vim.api.nvim_list_bufs, vim.api.nvim_buf_is_loaded
-- nvim_buf_is_loaded
vim.api.nvim_create_autocmd({'VimEnter', 'BufAdd', 'BufDelete'}, {
  desc = "(auto) hide statusbar for single buffer",
  -- ALT: command = "{x->if &laststatus!=x|let &laststatus=x|en}(len(getbufinfo({'buflisted':1})) <= 1 ? 0 : 3)"
  callback = function(t)
    local nr = 0
    for _, b in ipairs(buflist()) do
      if b == t.buf or bufloaded(b) then
        if not (b == t.buf and t.event == 'BufDelete') then
          nr = nr + 1
          if nr > 1 then break end
        end
      end
    end
    local v = nr > 1 and 3 or 0
    if o.laststatus ~= v then
      o.laststatus = v
    end
  end
})


-- statusline=%{%v:lua.require'lualine'.statusline()%}
-- o.statusline = '%t %y %l:%v'
o.statusline = '%<%f %h%m%r%=%y %-12.(%l:%c%V%) %P'
-- o.statusline = '%<%f%h%m%r%=%b 0x%B  %l,%c%V %P'
