" Name: Notches
" Fast highlighting: match Error /ENOMEM/
" CHECK: http://andrewradev.com/2011/08/06/making-vim-pretty-with-custom-colors/
" FIXME: background for labels don't match, when cursor is on same line
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
" TODO: use more guifg for nvim with the same ctermfg
let s:patterns = {
      \ 'Err': [160, "#d70000", 'ERR%(OR)=|BUG|REGR|XXX|WTF|BAD'],
      \ 'Add': [ 64, "#5f8700", 'ADD|SEE|REF|NEED|FIND|ALSO|BETTER'],
      \ 'Alt': [136, "#af8700", 'ALT|OR|CASE|THINK|IDEA|CHG|EXG'],
      \ 'Dev': [ 33, "#0087ff", 'DEV|ENH|HACK|RFC|SPL|DECIDE'],
      \ 'Tbd': [125, "#af005f", 'TODO|CHECK|TRY|MOVE|NOT|REQ|MAYBE'],
      \ 'Inf': [ 37, "#00afaf", 'INFO?|VAR'],
      \ 'Fix': [166, "#d75f00", 'BUT|FIX%(ME)?|WARN%(ING)?|ATT%(ENTION)?|REM%(OVE)?'],
      \ 'Did': [240, "#4e4e4e", 'DONE|FIXED|EXPL|TEMP'],
      \ 'Msg': [ 61, "#5f5faf", 'NOTE|USE|USAGE|DFL|STD|SUM%(MARY)?|DEBUG'],
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
    call matchadd('Notch'. k, '\v<('. v[2] .')>[:?*]=', -1)
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
