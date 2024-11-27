-- REF: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
local o, g = vim.opt, vim.g

--Set highlight on search
o.hlsearch = true

o.clipboard = 'unnamedplus'
if vim.fn.has("wsl") == 1 then
  -- OFF: from ":h 'clipboard"
  -- g.clipboard = {
  --   name = 'WslClipboard',
  --   copy = {
  --     ['+'] = 'clip.exe',
  --     ['*'] = 'clip.exe',
  --   },
  --   -- FAIL: too slow -- and does not copy from remote host in Citrix-VDI-WSL2 anyway
  --   paste = {
  --     ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  --     ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  --   },
  --   cache_enabled = 0,
  -- }

  -- SRC: https://www.reddit.com/r/neovim/comments/vxdjyb/comment/iknh207/
  -- ALT: copy-only (to workaround "mouse=a" in Citrix-VDI-WSL2)
  -- ALSO: $ sudo ln -fTs /mnt/c/WINDOWS/system32/clip.exe  /usr/local/bin/xci
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('Yank', { clear = true }),
    callback = function()
      vim.fn.system('clip.exe', vim.fn.getreg('"'))
    end,
  })
elseif vim.env.SSH_CONNECTION then
  g.clipboard = {
    name = 'SSH xcio',
    copy = {
      ['+'] = 'xci',
      ['*'] = 'xci',
    },
    paste = {
      ['+'] = 'xco',
      ['*'] = 'xco',
    },
    cache_enabled = 0,
  }
end

-- DISABLED: inherits "r.sh" from ranger which accesses too much files
o.shell = '/bin/sh'

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
-- DISABLED:FAIL:('a'): can't mouse copy/clipboard in WSL2 Citrix VDI
--   CANCELLED: can't mouse-click to switch tabs/buffers anymore
o.mouse = 'a'

--Enable break indent
o.breakindent = true

--Save undo history
o.undofile = true

--Case insensitive searching UNLESS /C or capital in search
o.ignorecase = true
o.smartcase = true

--Decrease update time for write(swap) and CursorHold
o.updatetime = 1000
--DISABLED('number'): I'm used to detect LSP finished loading by the time when column appears
vim.wo.signcolumn = 'auto'

o.cursorline = true
o.list = true
o.listchars = { tab = '▸ ', trail = '·', extends = '»', precedes = '«', nbsp = '␣' }
o.showbreak = ' '  -- ALT: '‥ .. ↪  ⮓ '

-- Set completeopt to have a better completion experience
o.completeopt = 'menuone,noselect' -- menu,
-- DISABLED:(<,>): don't wrap arrows in normal mode (nor DFL=b,s for <BS> and <Space>)
o.whichwrap = '[,]'


-- set foldenable
-- set foldcolumn=2        " fold levels ruler on left (clickable)
-- "set foldmethod=manual  " <expr|syntax|marker> -- syntax defines folds
o.foldlevel = 99 -- close folds below this depth, initially
-- set foldlevelstart=99   " close folds below this depth, on enter
-- " set foldopen=all      " open on cursor touch, DISABLED: prevents 'za' fold
-- set fillchars=fold:\    " don't place extra dashes on scr right after foldtext

o.formatoptions:append({ o = true })


--- Edit ============================
-- Tab/Space
o.expandtab = true  --Always use spaces for indent
o.shiftround = true
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2

-- Restrain vim from messing with '#' indent in python, etc.
o.cinkeys:remove({ '0#' })
o.indentkeys:remove({ '0#' })
o.commentstring = '# %s'

-- cursor can be positioned anywhere in V-BLOCK mode
o.virtualedit = 'block'

--- Move ============================
o.scrolloff = 3     -- context lines visible at screen edge when scroll
-- set sidescrolloff=4 " keep N columns on side visible when scrolling
-- set scrolljump=0    " minimum number of lines to scroll, OR: =-50 (50%)
-- set sidescroll=16   " horizontal scroll by 1 char (DFL:(0) -- half screen)
-- set nostartofline   " keep column when  <C-[fbud]> or [ggGHML], :25
