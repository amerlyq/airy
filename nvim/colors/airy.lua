-- DISABLED:PERF(hi clear): will restore default links
if vim.fn.exists 'syntax_on' then vim.api.nvim_command 'syntax reset' end
vim.g.colors_name = 'airy'

-- solarized
-- local bg = '#002b36'
-- local cg = '#073642'

-- true black
local bg = '#000000'
local cg = '#021b24'

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

  -- e5e WTF: cursor disappears after nvim->ranger->shell-<ranger->shell ※⡦⡃⣯⡪
  Cursor        = { fg = '#fdf6e3', bg = '#268bd2' },
  lCursor       = { link = "Cursor" },
  TermCursor    = { link = "Cursor" },
  TermCursorNC  = { link = "Cursor" },

  Normal        = { fg = '#93a1a1', bg = bg },
  FoldColumn    = { fg = '#839496', bg = cg },
  Folded        = { fg = '#839496', bg = cg, sp = bg, bold = true },
  Terminal      = { fg = '#93a1a1', bg = bg },
  ToolbarButton = { fg = '#93a1a1', bg = cg, bold = true },
  ToolbarLine   = { bg = cg },

  CursorLineNr = { fg = '#839496', bg = cg, bold = true },
  LineNr       = { fg = '#657b83', bg = bg },
  NonText      = { fg = '#657b83', bold = true },
  SpecialKey   = { fg = '#657b83', bg = cg, bold = true },
  SpellBad     = { fg = '#6c71c4', sp = '#6c71c4', undercurl = true },
  SpellCap     = { fg = '#6c71c4', sp = '#6c71c4', undercurl = true },
  SpellLocal   = { fg = '#b58900', sp = '#b58900', undercurl = true },
  SpellRare    = { fg = '#2aa198', sp = '#2aa198', undercurl = true },
  Title        = { fg = '#cb4b16', bold = true },


  DiffAdd    = { fg = '#859900', bg = '#001a00', sp = '#859900' },
  DiffChange = { fg = '#b58900', bg = '#1a1200', sp = '#b58900' },
  DiffDelete = { fg = '#dc322f', bg = '#1a0000', bold = true },
  DiffText   = { fg = '#268bd2', bg = bg, sp = '#268bd2' },

  GitSignsAddNr = { link = "DiffAdd" },
  GitSignsChangeNr = { link = "DiffChange" },
  GitSignsDeleteNr = { link = "DiffDelete" },
  GitSignsChangedeleteNr = { link = "DiffDelete" },

  -- GitGutterChange = { fg = '#b58900', bg = '#000000', sp = '#b58900', underline = true },
  -- GitGutterChange = { fg = '#b58900', bg = '#140c00', sp = '#b58900' },

  StatusLine   = { fg = '#839496', bg = cg },
  StatusLineNC = { fg = '#586e75', bg = cg, reverse = true },
  -- TabLine,TabLineFill          = { fg='#586e75', bg='#073642', reverse=true },
  TabLine      = { fg = '#828997', bg = cg },
  TabLineFill  = { fg = '#586e75', bg = cg },
  TabLineSel   = { fg = '#abb2bf', bg = bg, bold = true },
  VertSplit    = { fg = cg, bg = '#586e75' },

  ColorColumn  = { bg = cg },
  Conceal      = { fg = '#268bd2' },
  CursorColumn = { bg = cg },
  CursorLine   = { bg = bg, underline = true },
  Directory    = { fg = '#268bd2' },
  EndOfBuffer  = { fg = 'NONE' },
  ErrorMsg     = { fg = '#dc322f', bg = '#fdf6e3', reverse = true },
  IncSearch    = { fg = '#cb4b16', standout = true },
  MatchParen   = { fg = '#fdf6e3', bg = cg, bold = true },
  ModeMsg      = { fg = '#268bd2' },
  MoreMsg      = { fg = '#268bd2' },
  Pmenu        = { fg = '#93a1a1', bg = cg },
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
  VisualNOS    = { bg = cg, reverse = true },
  WarningMsg   = { fg = '#cb4b16', bold = true },
  WildMenu     = { fg = '#eee8d5', bg = cg, reverse = true },
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

  -- FIXED:(too shallow colors): https://github.com/p00f/nvim-ts-rainbow
  -- ALT:(vim/rainbow): ctermfgs = [160, 202, 178, 34, 33, 129]
  --   guifgs = ['#df0000', '#ff5f00', '#dfaf00', '#00af00', '#0087ff', '#af00ff']
  -- rainbowcol1 = { fg = '#cc241d' }, -- DFL: ctermfg=9  guifg=#cc241d
  -- rainbowcol2 = { fg = '#d65d0e' }, -- DFL: ctermfg=10 guifg=#a89984
  -- rainbowcol3 = { fg = '#d79921' }, -- DFL: ctermfg=11 guifg=#b16286
  -- rainbowcol4 = { fg = '#689d6a' }, -- DFL: ctermfg=12 guifg=#d79921
  -- rainbowcol5 = { fg = '#458588' }, -- DFL: ctermfg=13 guifg=#689d6a
  -- rainbowcol7 = { fg = '#b16286' }, -- DFL: ctermfg=15 guifg=#458588
  -- rainbowcol6 = { fg = '#a89984' }, -- DFL: ctermfg=14 guifg=#d65d0e

  -- OFF: textDocument/documentHighlight
  -- ALT: semshiSelected xxx ctermfg=231 ctermbg=161 guifg=#ffffff guibg=#d7005f
  LspReferenceText = { fg = '#ffffff', bg = '#d7005f' },
  LspReferenceRead = { fg = '#ffffff', bg = '#689d6a' },
  LspReferenceWrite = { fg = '#ffffff', bg = '#d65d0e' },

  -- TODO: reuse fore some TS* groups
  -- semshiLocal    xxx ctermfg=209 guifg=#ff875f
  -- semshiGlobal   xxx ctermfg=214 guifg=#ffaf00
  -- semshiImported xxx cterm=bold ctermfg=214 gui=bold guifg=#ffaf00
  -- semshiParameter xxx ctermfg=75 guifg=#5fafff
  -- semshiParameterUnused xxx cterm=underline ctermfg=117 gui=underline guifg=#87d7ff
  -- semshiFree     xxx ctermfg=218 guifg=#ffafd7
  -- semshiBuiltin  xxx ctermfg=207 guifg=#ff5fff
  -- semshiAttribute xxx ctermfg=49 guifg=#00ffaf
  -- semshiSelf     xxx ctermfg=249 guifg=#b2b2b2
  -- semshiUnresolved xxx cterm=underline ctermfg=226 gui=underline guifg=#ffff00
  -- semshiSelected xxx ctermfg=231 ctermbg=161 guifg=#ffffff guibg=#d7005f
  -- semshiErrorSign xxx ctermfg=231 ctermbg=160 guifg=#ffffff guibg=#d70000
  -- semshiErrorChar xxx ctermfg=231 ctermbg=160 guifg=#ffffff guibg=#d70000

  ["@variable"] = { link = "Normal" },
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
