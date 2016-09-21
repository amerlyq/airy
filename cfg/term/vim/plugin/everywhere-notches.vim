" Name: Notches
" Fast highlighting: match Error /ENOMEM/
" CHECK: http://andrewradev.com/2011/08/06/making-vim-pretty-with-custom-colors/
" FIXME: background for labels don't match, when cursor is on same line
" [_] FIXME: some notches (~ FIXME) are straigt instead of italic like comments
"   => Seems like it's result from combining (hi! + hi! link) from normal and post- hi! methods
"   !! THINK:TRY maybe it can be used to combine hi! in my nou.vim ?
" BUG: conflicts in perl: syntax '\u+:' has no hi!
" THINK? use autocompletion/snippets to cycle through possible notches
" DEV: combine with kana/vim-smartchr
"   https://github.com/AndrewRadev/switch.vim
"   integrate into Unite and deoplete (show candidates on specific button)
" 2016-09-14 [X] CHG: colors must have different tint then used in 'nou' outline/markup

if &cp||exists('g:loaded_notches')|finish|else|let g:loaded_notches=1|endif
if !has("autocmd") || v:version <= 701 | finish | endif

"" STD
" Black
" DarkBlue
" DarkGreen
" DarkCyan
" DarkRed
" DarkMagenta
" Brown, DarkYellow
" LightGray, LightGrey, Gray, Grey
" DarkGray, DarkGrey
" Blue, LightBlue
" Green, LightGreen
" Cyan, LightCyan
" Red, LightRed
" Magenta, LightMagenta
" Yellow, LightYellow
" White

"" Solarized
" base02    #073642  0 black    235 #262626
" red       #dc322f  1 red      160 #d70000
" green     #859900  2 green     64 #5f8700
" yellow    #b58900  3 yellow   136 #af8700
" blue      #268bd2  4 blue      33 #0087ff
" magenta   #d33682  5 magenta  125 #af005f
" cyan      #2aa198  6 cyan      37 #00afaf
" base2     #eee8d5  7 white    254 #d7d7af
" base03    #002b36  8 brblack  234 #1c1c1c
" orange    #cb4b16  9 brred    166 #d75f00
" base01    #586e75 10 brgreen  240 #4e4e4e
" base00    #657b83 11 bryellow 241 #585858
" base0     #839496 12 brblue   244 #808080
" violet    #6c71c4 13 brmagenta 61 #5f5faf
" base1     #93a1a1 14 brcyan   245 #8a8a8a
" base3     #fdf6e3 15 brwhite  230 #ffffd7

let g:everywhere_activated = 1
" UNUSED: 7,15 - whites, 0,8 - blacks, 11,12,14 - grays
" TODO:(nvim) split groups : dif guifg and same ctermfg
" Latin abbrev: SEE https://en.wikipedia.org/wiki/List_of_Latin_abbreviations
" E.G. exampli gratia (~ example given)
" I.E. id est (~ in especial, effectively)
let s:patterns = {
      \ 'Err': [196, "#ff2525", 'ERR%(OR)?|BUG|REGR|XXX|WTF|BAD'],
      \ 'Add': [ 76, "#5faf00", 'ADD|SEE|READ|REF|NEED|FIND|ALSO|BET%(TER)?|E\.G'],
      \ 'Alt': [178, "#dfaf00", 'ALT|OR|CASE|THINK|IDEA|CHG|I\.E'],
      \ 'Dev': [ 33, "#0087ff", 'DEV|ENH%(ANCE)?|HACK|RFC|SEP%(ARATE)?|SPL%(IT)?|DECIDE'],
      \ 'Tbd': [169, "#ff5faf", 'TODO|CHECK|TRY|MOVE|NOT|REQ%(UIRE)?|MAYBE'],
      \ 'Inf': [ 38, "#00afdf", 'INFO?|VAR'],
      \ 'Fix': [202, "#ff5f00", 'BUT|FIX%(ME)?|WARN%(ING)?|ATT%(ENTION)?|REM%(OVE)?'],
      \ 'Did': [243, "#767676", 'DONE|FIXED|EXPL%(AIN)?|TEMP'],
      \ 'Msg': [ 62, "#5f5fdf", 'NOTE|USE|USAGE|DFL|STD|SUM%(MARY)?|DEBUG'],
      \ }

function! s:everywhere_print(patts)
  tabnew
  setl winfixwidth winfixheight buftype=nofile bufhidden=wipe nobuflisted
  for [k,v] in items(a:patts)
    call append(line('.'), k .': '. v)
  endfor
endfunction


function! s:everywhere_define(cols)
  let locals = 'term=bold cterm=bold gui=bold ctermbg=NONE guibg=NONE'
  for [k,v] in items(a:cols)  "term=bold,underline guifg=#E01B1B
    exec printf('hi! Notch%s %s ctermfg=%s guifg=%s', k, locals, v[0], v[1])
  endfor
endfunction


function! s:everywhere_matches(patts)
  for [k,v] in items(a:patts)
    call matchadd('Notch'. k, '\v<('. v[2] .')>[:?!*.]=', -1)
  endfor
endfunction


function! s:everywhere_enable(mode)
  let g:everywhere_activated = a:mode
  augroup EverywhereNotches
    autocmd!
    if g:everywhere_activated
      au Syntax * call s:everywhere_matches(s:patterns)
      au ColorScheme * call s:everywhere_define(s:patterns)
    endif
  augroup END
endfunction


call s:everywhere_define(s:patterns)
call s:everywhere_enable(1)
" autocmd WinEnter,VimEnter * call s:everywhere_enable(1)

command! -bar -bang -nargs=0 EverywhereNotchesToggle
      \ call s:everywhere_enable(!g:everywhere_activated)
      \ | syntax off | syntax on

command! -bar -bang -nargs=0 EverywhereNotchesList
      \ call s:everywhere_print(s:patterns)
      \ | syntax off | syntax on

nnoremap <unique> [Toggle]T :EverywhereNotchesToggle<CR>
