
-- luasnip setup
-- https://github.com/L3MON4D3/LuaSnip
local luasnip = require 'luasnip'

-- nvim-cmp setup
-- https://github.com/hrsh7th/nvim-cmp
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
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
    -- { name = 'vsnip' },  -- For vsnip users.
    { name = 'luasnip' },   -- https://github.com/saadparwaiz1/cmp_luasnip
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },    -- https://github.com/hrsh7th/cmp-buffer
    { name = 'calc' },      -- https://github.com/hrsh7th/cmp-calc
    { name = 'fuzzy_buffer' },-- CFG: https://github.com/tzachar/cmp-fuzzy-buffer
  }, {
    { name = 'digraphs' },  -- https://github.com/dmitmel/cmp-digraphs
    { name = 'path' },      -- https://github.com/hrsh7th/cmp-path
    { name = 'cmdline' },   -- CFG: https://github.com/hrsh7th/cmp-cmdline
    -- { name = 'fuzzy_path' },-- CFG: https://github.com/tzachar/cmp-fuzzy-path
    { name = 'rg' },        -- https://github.com/lukas-reineke/cmp-rg
  }),
}

-- Set configuration for specific filetype.
-- cmp.setup.filetype('gitcommit', {
--   sources = cmp.config.sources({
--     { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
--   }, {
--     { name = 'buffer' },
--   })
-- })

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})
