--[Deferred loading of large plugins]

local lazy_plugins_loaded = false

local seen_filetypes = {}


--BAD: called each time you open buffers of the same type
--  WKRND: should wrap everything behind "require" singletons
--    BUT:FIXME: how to be with buffer-local mappings ?
local function load_ondemand()
  -- DEBUG: print(vim.inspect(g.lazy_filetypes))
  -- FIXED:(vim.bo.filetype): if ANY buffer had python
  if seen_filetypes['python'] then
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

  elseif seen_filetypes['lua'] then
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

  --HACK: add lazy plugins to &rtp
  vim.opt.packpath = { MYPLUG .. '/lazy', MYCONF }

  require 'plug.always'
  source_plugins()

  --WARN: loads all &rtp 'MYPLUG/preload' plugins AGAIN
  vim.cmd 'packloadall!'

  load_ondemand()
  source_after()

  lazy_plugins_loaded = true

  -- FUTURE:MAYBE: emit a user 'event' to chain my other pieces
  -- doautocmd User PluginsLoaded
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
