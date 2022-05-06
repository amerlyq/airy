--[nvim-cmp + luasnip]
vim.cmd [[
  packadd! nvim-cmp
  packadd! LuaSnip
  packadd! cmp-nvim-lsp
  packadd! cmp_luasnip
]]


-- https://github.com/hrsh7th/nvim-cmp
local cmp = require 'cmp'
-- https://github.com/L3MON4D3/LuaSnip
local luasnip = require 'luasnip'

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  -- CHECK Since updating to 0.7 I can no longer cycle through LSP completions with ctrl-n and ctrl-p : neovim ⌇⡢⡴⠋⠣
  --   https://www.reddit.com/r/neovim/comments/uehlkq/since_updating_to_07_i_can_no_longer_cycle/
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm {
      -- behavior = cmp.ConfirmBehavior.Replace,
      -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },  -- https://github.com/hrsh7th/cmp-nvim-lsp

    { name = 'luasnip' },   -- https://github.com/saadparwaiz1/cmp_luasnip
    -- ALT: disable filtering completion candidates by snippet's show_condition
    -- { name = 'luasnip', option = { use_show_condition = false } },

    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
    -- { name = 'vsnip' },  -- For vsnip users.
  }),
}

-- Loading snippets
luasnip.filetype_extend("all", { "_" })
require("luasnip.loaders.from_snipmate").lazy_load(opts)
-- require("luasnip.loaders.from_snipmate").load(opts) -- opts can be ommited
-- require("luasnip.loaders.from_lua").lazy_load(opts)


if vim.fn.has('vim_starting') == 0 then
vim.cmd [[
  packadd nvim-cmp
  packadd LuaSnip
  packadd cmp-nvim-lsp
  packadd cmp_luasnip
]]
end
