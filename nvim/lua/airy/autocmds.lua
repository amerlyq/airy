local autocmd = vim.api.nvim_create_autocmd


autocmd('FileType', {
  desc = "(Aux) filetype settings",
  pattern = 'lua',
  command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab'
})


-- Highlight on yank
autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank { higroup = "TextYank", timeout = 130 } end,
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
})


--FIXME: don't jump after moving between buffers
--FIXME:FAIL:(once=true): only restore position on first opening
--ALT: https://github.com/vladdoster/remember.nvim
--WARN: ShaDa should be loaded on startup for this to work
autocmd('BufReadPost', {
  desc = "(State) restore cursor position",
  command = 'silent! normal! g`"zvzz'
})


--SRC: https://github.com/cappyzawa/trim.nvim
--BET:(only modified lines): https://github.com/axelf4/vim-strip-trailing-whitespace
--   https://www.reddit.com/r/neovim/comments/em9ta9/vimstriptrailingwhitespace_now_supports_neovim/
--ALSO: https://github.com/ntpeters/vim-better-whitespace
--HACK:USAGE: save w/o formatting ":noa w" or ":set eventignore=BufWritePre | w | set eventignore="
--ALSO:
--   %s/\s\+$//e           -- remove unwanted spaces
--   %s/\($\n\s*\)\+\%$//  -- trim last line (OR: s/\\v%($\\_s*)+%$//) FAIL: uses RAM > maxmempattern
--   %s/\%^\n\+//          -- trim first line
--   %s/\(\n\n\)\n\+/\1/   -- replace multiple blank lines with a single line
autocmd("BufWritePre", {
  desc = "(Save) strip trailing spaces and empty lines",
  callback = function()
    local save = vim.fn.winsaveview()
    --BAD:(keeppatterns): prevents us using shortcut :g/xxx/s///e
    --TEMP: remove shit from MSTeams copy-paste
    vim.api.nvim_exec('keepjumps keeppatterns silent g/[\\r\\u200b]/s/[\\r\\u200b]//e', false)
    vim.api.nvim_exec('keepjumps keeppatterns silent g/\\s\\+$/s/\\s\\+$//e', false)
    vim.api.nvim_exec('keepjumps keeppatterns silent! /\\v^%(\\_s*\\S)@!/,$d_', false)
    --ALSO: let &fixeol=g:strip_lines
    vim.fn.winrestview(save)
  end
})


autocmd('CursorMoved', {
  desc = "(Nou) cvt ts -> date",
  callback = function()
    local word = vim.fn.expand('<cword>')
    if string.match(word, "^1%d%d%d%d%d%d%d%d%d$") then
      local ts = tonumber(word)
      local dts = os.date("%Y%m%d_%H%M%S", ts)
      vim.api.nvim_echo({{dts, 'None'}}, false, {})
    elseif vim.fn.match(word, '^\\v[\\u2800-\\u28FF]{4}$') == 0 then
      -- http://lua-users.org/wiki/LuaUnicode
      -- val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
      local vxfm = '\\=printf("%02x",and(char2nr(submatch(0)),0xff))'
      local hexts = vim.fn.substitute(word, '.', vxfm, 'g')
      local dts = os.date("%Y%m%d_%H%M%S", tonumber(hexts, 16))
      vim.api.nvim_echo({{dts, 'None'}}, false, {})
    elseif vim.fn.match(word, '^\\v[a-t][1-9abc][1-9a-v][MTWRFSU]?$') == 0 then
      -- ALT:(foreach): https://stackoverflow.com/questions/829063/how-to-iterate-individual-characters-in-lua-string
      local fcvt = function(v) if v <= 57 then return v - 48 else return v - 87 end end
      local y = fcvt(string.byte(word:sub(1,1))) + 2010
      local m = fcvt(string.byte(word:sub(2,2)))
      local d = fcvt(string.byte(word:sub(3,3)))
      -- TEMP: only decode 'ymd', FUT: also decode 'ymdhms'
      local dts = os.date("%Y-%m-%d", os.time({year=y, month=m, day=d, hour=0, min=0, sec=1}))
      vim.api.nvim_echo({{dts, 'None'}}, false, {})
    else
      local word = vim.fn.expand('<cWORD>')
      if vim.fn.match(word, '^\\v(%(19|20)\\d\\d)-(0\\d|1[012])-([012]\\d|3[01])>') == 0 then
        local _base31 = function(i)
          if i <= 9 then
            return string.char(string.byte("0") + i)
          else
            return string.char(string.byte("a") + (i - 10))
          end
        end
        local y = _base31((tonumber(word:sub(1,4)) - 2011) % 30 + 1)
        local m = _base31(tonumber(word:sub(6,7)))
        local d = _base31(tonumber(word:sub(9,10)))
        local dts = y .. m .. d
        vim.api.nvim_echo({{dts, 'None'}}, false, {})
      end
    end
  end
  -- command = "if expand('<cword>')=~'^1[0-9]{9}$'| "
  -- group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
})


--DISABLED: use "which-key" which overrules this
--HACK: Infinite wait on mappings, but timeout on keycodes (like <\e..>)
--WARN: you must eliminate clushing keymaps like ',x' and ',xy'
-- local K = require'keys.bind'.K
-- local o, g = vim.opt, vim.g
-- o.timeout =
-- set timeoutlen=1000 ttimeoutlen=32
-- set notimeout ttimeout
-- " Leave insert mode quickly
-- augroup FastEscape
--   autocmd!
--   au InsertEnter * set timeoutlen=0 ttimeoutlen=0
--   au InsertLeave * set timeoutlen=1000 ttimeoutlen=32
-- augroup END


-- SRC: https://github.com/wfxr/minimap.vim/issues
-- local g = vim.g
-- g.minimap_width = 8
-- g.minimap_auto_start = 1
-- g.minimap_auto_start_win_enter = 0
-- autocmd('WinEnter', {
--   -- SRC:https://github.com/wfxr/minimap.vim/issues/146
--   desc = "(HACK) don't ever enter minimap window/buffer",
--   callback = function()
--     local mmwinnr = vim.fn.bufwinnr("-MINIMAP-")
--     if mmwinnr == -1 then return end
--     if vim.fn.winnr() == mmwinnr then
--       -- Go to the other window.
--       vim.api.nvim_command("wincmd t")
--     end
--   end
-- })
