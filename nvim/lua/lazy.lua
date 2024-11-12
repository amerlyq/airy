--[Deferred loading of large plugins]

local lazy_plugins_loaded = false

local seen_filetypes = {}

local function ft_python()
  -- FIXME: load both for .py and .lua
  require 'plug.treesitter'
  require 'lsp.init'

  --FAIL: should load mappings only inside buffer
  if vim.bo.filetype == 'python' then
    vim.cmd [[
      augroup MyAutoCmd | autocmd! | augroup END
      runtime seize/jupyter-vim.vim
      packadd jupyter-vim
      let b:jupyter_kernel_type = &filetype
      call jupyter#load#MakeStandardCommands()
      call BufMap_jupyter_vim()
    ]]
  end
end


local function ft_cpp()
  require 'plug.treesitter'
  require 'lsp.init'
end


local function ft_lua()
  require 'plug.treesitter'
  require 'lsp.init'

  local t = seen_filetypes['lua']
  local p = vim.fn.fnamemodify(t.file, ":p")
  -- NOTE: load plugin immediately only for my colorscheme
  if p:match('/colors/airy.lua$') then
    vim.cmd [[ packadd nvim-colorizer.lua ]]
    require 'colorizer'.setup {
      'lua',
      'css',
      'javascript',
      html = { mode = 'foreground' }
    }
    require 'colorizer'.attach_to_buffer(t.buf)
  end
end


local function ft_vim()
  local t = seen_filetypes['vim']
  vim.cmd [[ packadd nvim-colorizer.lua ]]
  require 'colorizer'.setup {
    'vim',
    html = { mode = 'foreground' }
  }
  require 'colorizer'.attach_to_buffer(t.buf)
end


local function ft_lisp()
  require 'plug.treesitter'

  if vim.bo.filetype == 'lisp' then

    local bufnr = seen_filetypes['lisp'].buf
    local KB = vim.api.nvim_buf_set_keymap

    KB(bufnr, 'n', '<Space>z', '<Cmd>call vlime#plugin#ConnectREPL("127.0.0.1",7002)<CR>',
      { noremap = true, desc = 'Connect to a VLIME server'})

    KB(bufnr, 'n', '<Space>f', ':call vlime#plugin#SendToREPL(vlime#ui#CurTopExpr())<CR>',
      { noremap = true, silent = true, desc = 'Run (top-sexp)'})
    KB(bufnr, 'x', '<Space>f', ':<C-u>call vlime#plugin#SendToREPL(vlime#ui#CurSelection())<CR>',
      { noremap = true, silent = true, desc = 'Run (vsel)'})

    KB(bufnr, 'n', '<Space>k', '<Cmd>call vlime#plugin#SendToREPL("(_live)")<CR>',
      { noremap = true, desc = 'Run (_live)'})

    KB(bufnr, 'n', '<CR>', ':call vlime#plugin#SendToREPL(vlime#ui#CurTopExpr())<CR>'
      .. '<Cmd>call vlime#plugin#SendToREPL("(if (fboundp \'_live) (_live))")<CR>'
      , { noremap = true, desc = 'Eval top-expr for vlime + croaton' })
    KB(bufnr, 'x', '<CR>', ':<C-u>call vlime#plugin#SendToREPL(vlime#ui#CurSelection())<CR>',
      { noremap = true, desc = 'Eval for vlime selection' })

    -- BET? find outer scope (defun name) -- and exec it inof "symbol under cursor"
    KB(bufnr, 'n', '<BS>', ':call vlime#plugin#SendToREPL("(".vlime#ui#CurAtom().")")<CR>'
      , { noremap = true, silent = true, desc = 'Eval symbol under cursor as function' })


    vim.g.vlime_force_default_keys = true
    -- DEBUG: :echo g:vlime_default_window_settings["repl"]
    -- WTF: somehow it totally hides the REPL split window; BUT: that's actually OK
    vim.g.vlime_window_settings = {
      repl = {
        pos = "botright",
        size = 40,
        vertical = true
      }
    }

    -- TODO:(apply):VIZ: clojure fennel janet hy julia racket scheme lua lisp
    -- vim.cmd [[
    --   packadd conjure
    --   let g:conjure#mapping#def_word = ['gd']
    --   let g:conjure#mapping#doc_word = ['gD']
    --   let g:conjure#mapping#eval_root_form = "s"
    --   let g:conjure#mapping#eval_buf = "i"
    --   let g:conjure#highlight#enabled = v:true
    --   let g:conjure#highlight#timeout = 300
    -- ]]
    -- -- PERF: +8ms of startup time
    -- require("conjure.main").main()
    -- -- HACK: trigger FileType manually -- otherwise plugin doesn't work
    -- --   /cache/plugins/nvim/all/conjure/fnl/conjure/mapping.fnl:103
    -- require('conjure.mapping')['on-filetype']()
  end
end

local function ft_qf()
  if vim.bo.filetype == 'qf' then
    local bufnr = seen_filetypes['qf'].buf
    local KB = vim.api.nvim_buf_set_keymap
    local KBn = function(lhs, fn, s) KB(bufnr, 'n', lhs, '', { callback = fn, noremap = true, desc = s }) end

    -- OLD: https://github.com/stefandtw/quickfix-reflector.vim
    --   autocmd! FileType qf packadd quickfix-reflector.vim
    -- vim.cmd [[ packadd quickfix-reflector.vim ]]
    KB(bufnr, 'n', '<Bslash>e', '<Cmd>exe "BqfAutoToggle" | packadd quickfix-reflector.vim | copen<CR>'
      , { noremap = true, silent = true, desc = 'edit [QF] by reflector / disable Bqf' })

    -- SRC: https://github.com/gabrielpoca/replacer.nvim
    -- BAD: line numbers and lnum:col: disappers
    -- KBn('<Bslash>h', function() require("replacer").run {rename_files = false} end, "enable editing [QF]")
    ---- ERR: can't save QF by replacer.vim
    --   Error detected while processing BufWriteCmd Autocommands for "<buffer=31>":
    --   Error executing lua callback: Vim:E5300: Expected a Number or a String
    --   stack traceback:
    --           [C]: in function 'writefile'
    --           ...m/lazy/pack/ui/start/replacer.nvim/lua/replacer/init.lua:81: in function 'save'
    --           ...m/lazy/pack/ui/start/replacer.nvim/lua/replacer/init.lua:200: in function <...m/lazy/pack/ui/start/replacer.nvim/lua/replacer/init.lua:200>
    -- KBn('<Bslash>H', function() require("replacer").save {rename_files = false} end, "save edited [QF]")
  end
end


--BAD: called each time you open buffers of the same type
--  WKRND: should wrap everything behind "require" singletons
--    BUT:FIXME: how to be with buffer-local mappings ?
local function load_ondemand()
  -- DEBUG: print(vim.inspect(g.lazy_filetypes))
  -- FIXED:(vim.bo.filetype): if ANY buffer had python
  if seen_filetypes['qf'] then
    ft_qf()
  elseif seen_filetypes['python'] then
    ft_python()
  elseif seen_filetypes['lisp'] then
    ft_lisp()
  elseif seen_filetypes['c'] or seen_filetypes['cpp'] then
    ft_cpp()
  elseif seen_filetypes['lua'] then
    ft_lua()
  elseif seen_filetypes['vim'] then
    ft_vim()
  end
end

local function on_filetype(t)
  if t then
    seen_filetypes[t.match] = t
  end
  if lazy_plugins_loaded then
    load_ondemand()
  end
end

local function source_plugins()
  -- OR: vim.fn.glob(MYCONF .. '/plugin/*.vim',1,1)
  vim.cmd [[
    for f in glob('/@/airy/nvim/plugin/*.vim',1,1)| exe 'source' fnameescape(f) |endfor
    for f in glob('/@/airy/nvim/plugin/*.lua',1,1)| exe 'luafile' fnameescape(f)|endfor
    source $VIMRUNTIME/plugin/rplugin.vim
  ]]
end

local function source_after()
  -- WARN: packadd adds "after" to &rtp but skips loading
  --   VIZ: pack/*/opt/{name}/{plugin,ftdetect}/**/*.{vim,lua}
  vim.cmd [[
    runtime! after/plugin/**/*.vim
    runtime! after/plugin/**/*.lua
  ]]
  -- ALT:VIZ: find -path '*/after/plugin/*'
  -- vim.cmd [[ runtime! OPT after/plugin/*.lua ]]
  -- vim.cmd [[ runtime! OPT after/plugin/**/*.vim  after/plugin/**/*.lua ]]
  -- local tosrc = vim.api.nvim_get_runtime_file('after/plugin/**/*.lua', true)
  -- for _, f in ipairs(tosrc) do vim.cmd [[ source f ]] end
end

local function on_delayed_startup()

  --SRC: https://github.com/lewis6991/impatient.nvim
  --require('impatient')
  --USAGE :LuaCacheProfile
  -- require('impatient').enable_profile()

  --DEBUG: vim.cmd 'set pp'
  -- print(vim.inspect(vim.opt.packpath))

  --HACK: add lazy plugins to &rtp
  --DISABLED:(MYCONF,...): prevent duplicates in &rtp
  --  NOTE: always treat MYCONF as preload-only and don't insert it here again
  vim.opt.packpath = { MYPLUG .. '/lazy' }

  require 'plug.always'
  source_plugins()

  --WARN: loads all &rtp 'MYPLUG/preload' plugins AGAIN
  -- print(vim.inspect(vim.opt.runtimepath))
  vim.cmd 'packloadall!'

  load_ondemand()
  source_after()

  lazy_plugins_loaded = true

  -- FUTURE:MAYBE: emit a user 'event' to chain my other pieces
  -- doautocmd User PluginsLoaded
  vim.api.nvim_command('doautocmd <nomodeline> User LazyPluginsLoaded')
  --DISABLED: very distracting periphery text change
  -- vim.notify("Lazy: DONE")
  -- vim.notify(("%s %s"):format(count, name), res == "err" and vim.log.levels.ERROR)
end

vim.api.nvim_create_autocmd('FileType', {
  desc = "(Aux) register filetypes or trigger deferred packadd",
  callback = on_filetype
})


-- vim.defer_fn(on_delayed_startup, 250)
vim.api.nvim_create_autocmd('VimEnter', {
  desc = "(Lazy) loading ALL deferred plugins",
  -- callback = on_delayed_startup
  callback = function()
    -- vim.cmd [[
    --   for f in glob('/@/airy/nvim/plugin/pack/airy/start/*/plugin/*.vim',1,1)| exe 'source' fnameescape(f) |endfor
    -- ]]
    -- vim.cmd 'packadd dictl'
    vim.defer_fn(on_delayed_startup, 8)
  end
})


-- NOTE: using wait=1s to exit from short sessions immediately
-- vim.fn.timer_start(1000, on_delayed_startup)
-- vim.api.nvim_create_autocmd('VimEnter', {
--   desc = "Lazy packadd by filetype + cmp",
--   callback = on_delayed_startup
-- })
