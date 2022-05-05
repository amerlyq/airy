"%SUM: airy.based_on(vim-solarized8)

if !(&termguicolors && &background==#'dark') | verb throw "Incompatible" | en
" set bg=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = 'airy'

hi! link Boolean Constant
hi! link Character Constant
hi! link Conditional Statement
hi! link Debug Special
hi! link Define PreProc
hi! link Delimiter Special
hi! link Exception Statement
hi! link Float Constant
hi! link Function Identifier
hi! link Include PreProc
hi! link Keyword Statement
hi! link Label Statement
hi! link Macro PreProc
hi! link Number Constant
hi! link Operator Statement
hi! link PreCondit PreProc
hi! link QuickFixLine Search
hi! link Repeat Statement
hi! link SpecialChar Special
hi! link SpecialComment Special
hi! link StatusLineTerm StatusLine
hi! link StatusLineTermNC StatusLineNC
hi! link StorageClass Type
hi! link String Constant
hi! link Structure Type
hi! link Tag Special
hi! link Typedef Type
hi! link lCursor Cursor

hi Cursor guifg=#fdf6e3 guibg=#268bd2 gui=NONE cterm=NONE

" let g:terminal_ansi_colors = ['#073642', '#dc322f', '#859900', '#b58900', '#268bd2', '#d33682', '#2aa198', '#eee8d5', '#002b36', '#cb4b16', '#586e75', '#657b83', '#839496', '#6c71c4', '#93a1a1', '#fdf6e3']
hi! link TermCursor Cursor
hi TermCursorNC guifg=#002b36 guibg=#586e75 gui=NONE cterm=NONE
let g:terminal_color_0 = '#073642'
let g:terminal_color_1 = '#dc322f'
let g:terminal_color_2 = '#859900'
let g:terminal_color_3 = '#b58900'
let g:terminal_color_4 = '#268bd2'
let g:terminal_color_5 = '#d33682'
let g:terminal_color_6 = '#2aa198'
let g:terminal_color_7 = '#eee8d5'
let g:terminal_color_8 = '#002b36'
let g:terminal_color_9 = '#cb4b16'
let g:terminal_color_10 = '#586e75'
let g:terminal_color_11 = '#657b83'
let g:terminal_color_12 = '#839496'
let g:terminal_color_13 = '#6c71c4'
let g:terminal_color_14 = '#93a1a1'
let g:terminal_color_15 = '#fdf6e3'

hi Normal guifg=#93a1a1 guibg=#002b36 gui=NONE cterm=NONE
hi FoldColumn guifg=#839496 guibg=#073642 gui=NONE cterm=NONE
hi Folded guifg=#839496 guibg=#073642 guisp=#002b36 gui=bold cterm=bold
hi Terminal guifg=fg guibg=#002b36 gui=NONE cterm=NONE
hi ToolbarButton guifg=#93a1a1 guibg=#073642 gui=bold cterm=bold
hi ToolbarLine guifg=NONE guibg=#073642 gui=NONE cterm=NONE

hi CursorLineNr guifg=#839496 guibg=#073642 gui=bold cterm=bold
hi LineNr guifg=#657b83 guibg=#073642 gui=NONE cterm=NONE
hi NonText guifg=#657b83 guibg=NONE gui=bold cterm=bold
hi SpecialKey guifg=#657b83 guibg=#073642 gui=bold cterm=bold
hi SpellBad guifg=#6c71c4 guibg=NONE guisp=#6c71c4 gui=undercurl cterm=underline
hi SpellCap guifg=#6c71c4 guibg=NONE guisp=#6c71c4 gui=undercurl cterm=underline
hi SpellLocal guifg=#b58900 guibg=NONE guisp=#b58900 gui=undercurl cterm=underline
hi SpellRare guifg=#2aa198 guibg=NONE guisp=#2aa198 gui=undercurl cterm=underline
hi Title guifg=#cb4b16 guibg=NONE gui=bold cterm=bold


hi DiffAdd guifg=#859900 guibg=#073642 guisp=#859900 gui=NONE cterm=NONE
hi DiffChange guifg=#b58900 guibg=#073642 guisp=#b58900 gui=NONE cterm=NONE
hi DiffDelete guifg=#dc322f guibg=#073642 gui=bold cterm=bold
hi DiffText guifg=#268bd2 guibg=#073642 guisp=#268bd2 gui=NONE cterm=NONE

hi StatusLine guifg=#839496 guibg=#073642 gui=reverse cterm=reverse
hi StatusLineNC guifg=#586e75 guibg=#073642 gui=reverse cterm=reverse
hi TabLine guifg=#586e75 guibg=#073642 gui=reverse cterm=reverse
hi TabLineFill guifg=#586e75 guibg=#073642 gui=reverse cterm=reverse
hi TabLineSel guifg=#839496 guibg=#073642 gui=reverse cterm=reverse
hi VertSplit guifg=#073642 guibg=#586e75 gui=NONE cterm=NONE

hi ColorColumn guifg=NONE guibg=#073642 gui=NONE cterm=NONE
hi Conceal guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi CursorColumn guifg=NONE guibg=#073642 gui=NONE cterm=NONE
hi CursorLine guifg=NONE guibg=#073642 gui=NONE cterm=NONE
hi Directory guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi EndOfBuffer guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi ErrorMsg guifg=#dc322f guibg=#fdf6e3 gui=reverse cterm=reverse
hi IncSearch guifg=#cb4b16 guibg=NONE gui=standout cterm=standout
hi MatchParen guifg=#fdf6e3 guibg=#073642 gui=bold cterm=bold
hi ModeMsg guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi MoreMsg guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi Pmenu guifg=#93a1a1 guibg=#073642 gui=NONE cterm=NONE
hi PmenuSbar guifg=NONE guibg=#586e75 gui=NONE cterm=NONE
hi PmenuSel guifg=#eee8d5 guibg=#657b83 gui=NONE cterm=NONE
hi PmenuThumb guifg=NONE guibg=#839496 gui=NONE cterm=NONE
hi Question guifg=#2aa198 guibg=NONE gui=bold cterm=bold
hi Search guifg=#b58900 guibg=NONE gui=reverse cterm=reverse
hi SignColumn guifg=#839496 guibg=NONE gui=NONE cterm=NONE
hi Visual guifg=#586e75 guibg=#002b36 gui=reverse cterm=reverse
hi VisualNOS guifg=NONE guibg=#073642 gui=reverse cterm=reverse
hi WarningMsg guifg=#cb4b16 guibg=NONE gui=bold cterm=bold
hi WildMenu guifg=#eee8d5 guibg=#073642 gui=reverse cterm=reverse
hi Comment guifg=#586e75 guibg=NONE gui=italic cterm=italic
hi Constant guifg=#2aa198 guibg=NONE gui=NONE cterm=NONE
hi CursorIM guifg=NONE guibg=fg gui=NONE cterm=NONE
hi Error guifg=#dc322f guibg=#fdf6e3 gui=bold,reverse cterm=bold,reverse
hi Identifier guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi Ignore guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi PreProc guifg=#cb4b16 guibg=NONE gui=NONE cterm=NONE
hi Special guifg=#cb4b16 guibg=NONE gui=NONE cterm=NONE
hi Statement guifg=#859900 guibg=NONE gui=NONE cterm=NONE
hi Todo guifg=#d33682 guibg=NONE gui=bold cterm=bold
hi Type guifg=#b58900 guibg=NONE gui=NONE cterm=NONE
hi Underlined guifg=#6c71c4 guibg=NONE gui=NONE cterm=NONE
hi NormalMode guifg=#839496 guibg=#fdf6e3 gui=reverse cterm=reverse
hi InsertMode guifg=#2aa198 guibg=#fdf6e3 gui=reverse cterm=reverse
hi ReplaceMode guifg=#cb4b16 guibg=#fdf6e3 gui=reverse cterm=reverse
hi VisualMode guifg=#d33682 guibg=#fdf6e3 gui=reverse cterm=reverse
hi CommandMode guifg=#d33682 guibg=#fdf6e3 gui=reverse cterm=reverse


hi! link vimVar Identifier
hi! link vimFunc Function
hi! link vimUserFunc Function
hi! link helpSpecial Special
hi! link vimSet Normal
hi! link vimSetEqual Normal
hi vimCommentString guifg=#6c71c4 guibg=NONE gui=NONE cterm=NONE
hi vimCommand guifg=#b58900 guibg=NONE gui=NONE cterm=NONE
hi vimCmdSep guifg=#268bd2 guibg=NONE gui=bold cterm=bold
hi helpExample guifg=#93a1a1 guibg=NONE gui=NONE cterm=NONE
hi helpOption guifg=#2aa198 guibg=NONE gui=NONE cterm=NONE
hi helpNote guifg=#d33682 guibg=NONE gui=NONE cterm=NONE
hi helpVim guifg=#d33682 guibg=NONE gui=NONE cterm=NONE
hi helpHyperTextJump guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi helpHyperTextEntry guifg=#859900 guibg=NONE gui=NONE cterm=NONE
hi vimIsCommand guifg=#657b83 guibg=NONE gui=NONE cterm=NONE
hi vimSynMtchOpt guifg=#b58900 guibg=NONE gui=NONE cterm=NONE
hi vimSynType guifg=#2aa198 guibg=NONE gui=NONE cterm=NONE
hi vimHiLink guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi vimHiGroup guifg=#268bd2 guibg=NONE gui=NONE cterm=NONE
hi vimGroup guifg=#268bd2 guibg=NONE gui=bold cterm=bold
hi! link diffAdded Statement
hi! link diffLine Identifier
