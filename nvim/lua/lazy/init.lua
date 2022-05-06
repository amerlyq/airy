--[Deferred loading of large plugins]

local lazy_done = false

local seen_filetypes = {}


local function load_now(t)
  if t.match == 'lua' then
    local p = vim.fn.fnamemodify(t.file, ":p")
    -- NOTE: load plugin immediately only for my colorscheme
    if p:match('/colors/airy.lua$') then
      vim.cmd [[ packadd nvim-colorizer.lua ]]
      require'colorizer'.setup {
        'lua';
        'css';
        'javascript';
        html = { mode = 'foreground'; }
      }
      require'colorizer'.attach_to_buffer(t.buf)
    end
  end
end


local function load_lazy()
  -- DEBUG: print(vim.inspect(g.lazy_filetypes))
  -- FIXED:(vim.bo.filetype): if ANY buffer had python
  if seen_filetypes['python'] then
    require 'lazy.treesitter'
    require 'lazy.lsp'
  end
end


local function lazy_ft(t)
  if t then
    seen_filetypes[t.match] = true
    load_now(t)
  end
  if lazy_done then
    load_lazy()
  end
end


local function lazy_packadd()
  require 'lazy.cmp' -- +luasnip

  lazy_done = true
  load_lazy()

  -- WARN: packadd adds "after" to &rtp but skips loading
  --   VIZ: pack/*/opt/{name}/{plugin,ftdetect}/**/*.{vim,lua}

  -- DEBUG: what files ':runtime' found
  -- vim.opt.verbose = 2

  -- VIZ: find -path '*/after/plugin/*'
  vim.cmd [[ runtime! OPT after/plugin/*.lua ]]
  -- vim.cmd [[ runtime! OPT  after/plugin/**/*.vim  after/plugin/**/*.lua ]]
  -- local tosrc = vim.api.nvim_get_runtime_file('after/plugin/**/*.lua', true)
  -- for _, f in ipairs(tosrc) do
  --   vim.cmd [[ source f ]]
  -- end

  -- FUTURE:MAYBE: emit a user 'event' to chain my other pieces
  -- doautocmd User PluginsLoaded
  vim.notify("DONE: lazy")
  -- vim.notify(("%s %s"):format(count, name), res == "err" and vim.log.levels.ERROR)
end


vim.api.nvim_create_autocmd('FileType', {
  desc = "(Aux) register filetypes or trigger deferred packadd",
  callback = lazy_ft
})

-- NOTE: using wait=1s to exit from short sessions immediately
vim.fn.timer_start(1000, lazy_packadd)
-- vim.api.nvim_create_autocmd('VimEnter', {
--   desc = "Lazy packadd by filetype + cmp",
--   callback = lazy_packadd
-- })
