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
    -- FIXME: load both for .py and .lua
    require 'lazy.treesitter'
    require 'lazy.lsp'

    --FAIL: should load mappings only inside buffer
    if vim.bo.filetype == 'python' then
      vim.cmd [[
        augroup MyAutoCmd | autocmd! | augroup END
        runtime seize/jupyter-vim.vim
        packadd jupyter-vim
        call BufMap_jupyter_vim()
      ]]
    end
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


local function load_always()
  require 'lazy.cmp' -- +luasnip

  -- Gitsigns
  -- Add git related info in the signs columns and popups
  --DEP: plenary.nvim
  --SRC: https://github.com/lewis6991/gitsigns.nvim
  require('gitsigns').setup {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
  }

  --Enable Comment.nvim
  -- https://github.com/numToStr/Comment.nvim
  -- require('Comment').setup()
  require('nvim_comment').setup {
    -- HACK: pull "commentstring" based on HEREDOC language
    -- hook = function()
    --   if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
    --     require("ts_context_commentstring.internal").update_commentstring()
    --   end
    -- end
  }
end


local function source_plugins()
  -- WARN: packadd adds "after" to &rtp but skips loading
  --   VIZ: pack/*/opt/{name}/{plugin,ftdetect}/**/*.{vim,lua}

  -- DEBUG: what files ':runtime' found
  -- vim.opt.verbose = 2

  --WARN: marks (last position) is only written to ShaDa on vim exit
  --  MAYBE: use "au BufWipeout :wshada" to store them
  --ALSO:OR: vim.cmd('source ' .. vim.env.VIMRUNTIME .. '/plugin/rplugin.vim')
  vim.cmd [[
    runtime! /@/airy/nvim/plugin/*.vim
    runtime! /@/airy/nvim/plugin/*.lua
    source $VIMRUNTIME/plugin/rplugin.vim

    packloadall
    runtime! after/plugin/**/*.vim
    runtime! after/plugin/**/*.lua
  ]]

  -- VIZ: find -path '*/after/plugin/*'
  -- vim.cmd [[ runtime! OPT after/plugin/*.lua ]]
  -- vim.cmd [[ runtime! OPT  after/plugin/**/*.vim  after/plugin/**/*.lua ]]
  -- local tosrc = vim.api.nvim_get_runtime_file('after/plugin/**/*.lua', true)
  -- for _, f in ipairs(tosrc) do
  --   vim.cmd [[ source f ]]
  -- end
end


local function lazy_packadd()
  --SRC: https://github.com/lewis6991/impatient.nvim
  require('impatient')
  --USAGE :LuaCacheProfile
  -- require('impatient').enable_profile()

  load_always()
  lazy_done = true
  load_lazy()
  source_plugins()

  vim.cmd 'set shadafile= | rshada'

  -- FUTURE:MAYBE: emit a user 'event' to chain my other pieces
  -- doautocmd User PluginsLoaded
  vim.notify("Lazy: DONE")
  -- vim.notify(("%s %s"):format(count, name), res == "err" and vim.log.levels.ERROR)
end


vim.api.nvim_create_autocmd('FileType', {
  desc = "(Aux) register filetypes or trigger deferred packadd",
  callback = lazy_ft
})


vim.defer_fn(lazy_packadd, 250)
-- vim.api.nvim_create_autocmd('VimEnter', {
--   desc = "(Lazy) loading ALL deferred plugins",
--   callback = lazy_packadd
-- })


-- NOTE: using wait=1s to exit from short sessions immediately
-- vim.fn.timer_start(1000, lazy_packadd)
-- vim.api.nvim_create_autocmd('VimEnter', {
--   desc = "Lazy packadd by filetype + cmp",
--   callback = lazy_packadd
-- })

