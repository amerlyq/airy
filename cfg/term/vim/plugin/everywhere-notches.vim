" Name: Notches
" Fast highlighting: match Error /ENOMEM/
" CHECK: http://andrewradev.com/2011/08/06/making-vim-pretty-with-custom-colors/
" FIXME: background for labels don't match, when cursor is on same line
" THINK? use autocompletion/snippets to cycle through possible notches
" DEV: combine with kana/vim-smartchr
"   https://github.com/AndrewRadev/switch.vim
"   integrate into Unite and deoplete (show candidates on specific button)
" CHG: colors must have different tint then used in 'nou' outline/markup

if &cp||exists('g:loaded_notches')|finish|else|let g:loaded_notches=1|endif
if !has("autocmd") || v:version <= 701 | finish | endif

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

let g:everywhere_activated = 1
" UNUSED: 6 - light blue, 7,15 - whites, 0,8 - blacks, 11,12,14 - grays
" TODO: use more guifg for nvim with the same ctermfg
let s:patterns = {
      \ 'Err': [ 1, "#dc322f", 'ERR%(OR)=|BUG|REGR|XXX|WTF|BAD'],
      \ 'Fix': [ 9, "#dd6616", 'BUT|FIX%(ME)?|WARN%(ING)?|ATTENTION|REM%(OVE)?'],
      \ 'Add': [ 2, "#859900", 'ADD|SEE|REF|NEED|FIND|ALSO|BETTER'],
      \ 'Did': [10, "#586e75", 'DONE|FIXED|EXPL|TEMP'],
      \ 'Dev': [ 4, "#268bd2", 'DEV|ENH|HACK|RFC|SPL|DECIDE'],
      \ 'Msg': [13, "#6c71c4", 'NOTE|USE|USAGE|DFL|STD|SUMMARY'],
      \ 'Tbd': [ 5, "#d33682", 'TODO|CHECK|TRY|MOVE|NOT|REQ|MAYBE'],
      \ 'Alt': [ 3, "#c5a900", 'ALT|OR|CASE|THINK|IDEA|CHG'],
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
