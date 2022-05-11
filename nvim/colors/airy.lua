-- DISABLED:PERF(hi clear): will restore default links
if vim.fn.exists 'syntax_on' then vim.api.nvim_command 'syntax reset' end
vim.g.colors_name = 'airy'

-- VIZ: fg,bg,sp,gui = bold italic reverse standout underline underlineline undercurl underdot underdash strikethrough
-- ALSO:(default=true): don't override existing definition
local highlights = {

  Boolean          = { link = "Constant" },
  Character        = { link = "Constant" },
  Conditional      = { link = "Statement" },
  Debug            = { link = "Special" },
  Define           = { link = "PreProc" },
  Delimiter        = { link = "Special" },
  Exception        = { link = "Statement" },
  Float            = { link = "Constant" },
  Function         = { link = "Identifier" },
  Include          = { link = "PreProc" },
  Keyword          = { link = "Statement" },
  Label            = { link = "Statement" },
  Macro            = { link = "PreProc" },
  Number           = { link = "Constant" },
  Operator         = { link = "Statement" },
  PreCondit        = { link = "PreProc" },
  QuickFixLine     = { link = "Search" },
  Repeat           = { link = "Statement" },
  SpecialChar      = { link = "Special" },
  SpecialComment   = { link = "Special" },
  StatusLineTerm   = { link = "StatusLine" },
  StatusLineTermNC = { link = "StatusLineNC" },
  StorageClass     = { link = "Type" },
  String           = { link = "Constant" },
  Structure        = { link = "Type" },
  Tag              = { link = "Special" },
  Typedef          = { link = "Type" },
  lCursor          = { link = "Cursor" },

  Cursor = { fg = '#fdf6e3', bg = '#268bd2' },

  Normal        = { fg = '#93a1a1', bg = '#002b36' },
  FoldColumn    = { fg = '#839496', bg = '#073642' },
  Folded        = { fg = '#839496', bg = '#073642', sp = '#002b36', bold = true },
  Terminal      = { fg = '#93a1a1', bg = '#002b36' },
  ToolbarButton = { fg = '#93a1a1', bg = '#073642', bold = true },
  ToolbarLine   = { bg = '#073642' },

  CursorLineNr = { fg = '#839496', bg = '#073642', bold = true },
  LineNr       = { fg = '#657b83', bg = '#073642' },
  NonText      = { fg = '#657b83', bold = true },
  SpecialKey   = { fg = '#657b83', bg = '#073642', bold = true },
  SpellBad     = { fg = '#6c71c4', sp = '#6c71c4', undercurl = true },
  SpellCap     = { fg = '#6c71c4', sp = '#6c71c4', undercurl = true },
  SpellLocal   = { fg = '#b58900', sp = '#b58900', undercurl = true },
  SpellRare    = { fg = '#2aa198', sp = '#2aa198', undercurl = true },
  Title        = { fg = '#cb4b16', bold = true },


  DiffAdd    = { fg = '#859900', bg = '#073642', sp = '#859900' },
  DiffChange = { fg = '#b58900', bg = '#073642', sp = '#b58900' },
  DiffDelete = { fg = '#dc322f', bg = '#073642', bold = true },
  DiffText   = { fg = '#268bd2', bg = '#073642', sp = '#268bd2' },

  StatusLine   = { fg = '#839496', bg = '#073642' },
  StatusLineNC = { fg = '#586e75', bg = '#073642', reverse = true },
  -- TabLine,TabLineFill          = { fg='#586e75', bg='#073642', reverse=true },
  TabLine      = { fg = '#828997', bg = '#073642' },
  TabLineFill  = { fg = '#586e75', bg = '#073642' },
  TabLineSel   = { fg = '#abb2bf', bg = '#002b36', bold = true },
  VertSplit    = { fg = '#073642', bg = '#586e75' },

  ColorColumn  = { bg = '#073642' },
  Conceal      = { fg = '#268bd2' },
  CursorColumn = { bg = '#073642' },
  CursorLine   = { bg = '#073642' },
  Directory    = { fg = '#268bd2' },
  EndOfBuffer  = { fg = 'NONE' },
  ErrorMsg     = { fg = '#dc322f', bg = '#fdf6e3', reverse = true },
  IncSearch    = { fg = '#cb4b16', standout = true },
  MatchParen   = { fg = '#fdf6e3', bg = '#073642', bold = true },
  ModeMsg      = { fg = '#268bd2' },
  MoreMsg      = { fg = '#268bd2' },
  Pmenu        = { fg = '#93a1a1', bg = '#073642' },
  PmenuSbar    = { bg = '#586e75' },
  PmenuSel     = { fg = '#eee8d5', bg = '#657b83' },
  PmenuThumb   = { bg = '#839496' },
  Question     = { fg = '#2aa198', bold = true },
  Search       = { fg = '#b58900', reverse = true },
  --FIXED: dark „fissure“ on the left of linenumbers column
  -- [DiffAdd, DiffChange, DiffDelete, DiffText, SignColumn, LineNr, FoldColumn, SpecialKey]
  SignColumn   = { link = 'LineNr' },
  -- SignColumn       = { fg='#839496' },
  Visual       = { fg = '#586e75', bg = '#002b36', reverse = true },
  VisualNOS    = { bg = '#073642', reverse = true },
  WarningMsg   = { fg = '#cb4b16', bold = true },
  WildMenu     = { fg = '#eee8d5', bg = '#073642', reverse = true },
  Comment      = { fg = '#586e75', italic = true },
  Constant     = { fg = '#2aa198' },
  CursorIM     = { bg = '#93a1a1' },
  Error        = { fg = '#dc322f', bg = '#fdf6e3', bold = true, reverse = true },
  Identifier   = { fg = '#268bd2' },
  Ignore       = { fg = 'NONE' },
  PreProc      = { fg = '#cb4b16' },
  Special      = { fg = '#cb4b16' },
  Statement    = { fg = '#859900' },
  Todo         = { fg = '#d33682', bold = true },
  Type         = { fg = '#b58900' },
  Underlined   = { fg = '#6c71c4' },
  NormalMode   = { fg = '#839496', bg = '#fdf6e3', reverse = true },
  InsertMode   = { fg = '#2aa198', bg = '#fdf6e3', reverse = true },
  ReplaceMode  = { fg = '#cb4b16', bg = '#fdf6e3', reverse = true },
  VisualMode   = { fg = '#d33682', bg = '#fdf6e3', reverse = true },
  CommandMode  = { fg = '#d33682', bg = '#fdf6e3', reverse = true },

  --FIXED: make 'listchars' hardly visible
  -- vim.highlight.create('Whitespace', {ctermfg=0, ctermbg=8, guifg='#073642', guibg='#002b36', gui=nocombine}, false)
  Whitespace = { fg = '#072f3b' },

  --FIXED: default yank hl is irritating
  TextYank = { reverse = true },

  --FIXED: wrong .py "def …" color
  -- vim.highlight.link("TSKeywordFunction", "TSKeyword", true)
  -- TSFuncBuiltin    = { fg='#268bd2' },
  TSFuncBuiltin = { fg = '#4f78d2' },

  -- FIXED: too bright hi! for !neovim LSP ※⡢⡔⢀⠔
  DiagnosticError = { fg = '#870000', ctermfg = 88 },
  DiagnosticWarn  = { fg = '#875f00', ctermfg = 94 },
  -- DiagnosticUnderlineWarn term=underline gui=underline guisp=#5f5f00
}

local nvim_set_hl = vim.api.nvim_set_hl
-- local fnm = 'nvim_set_hl'
-- local reqs = {}
for nm, attrs in pairs(highlights) do
  nvim_set_hl(0, nm, attrs)
  -- table.insert(reqs, {fnm, {0, nm, attrs}})
end
-- FAIL: nvim_call_atomic not available via Lua on nvim 0.4.3 or 0.4.4 · Issue #13191 · neovim/neovim ⌇⡢⡵⠲⡀
--   https://github.com/neovim/neovim/issues/13191
-- vim.api.nvim_call_atomic(reqs)
