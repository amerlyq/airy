" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
" Fast highlighting: match Error /ENOMEM/

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
let s:colors = { 'Err': 1, 'Fix': 9, 'Add': 2, 'Msg': 7, 'Tbd': 5, 'Alt': 3 }
let s:patterns = {
      \ 'Err': 'ERR(OR)=|BUG',
      \ 'Fix': 'FIX(ME)=|WARNING',
      \ 'Add': 'ADD',
      \ 'Msg': 'NOTE',
      \ 'Tbd': 'TODO',
      \ 'Alt': 'ALT|OR',
      \ }


function! s:everywhere_define(cols)
  for [k,v] in items(a:cols)  "term=bold,underline guifg=#E01B1B
    exec 'hi! Note'. k .' term=bold cterm=bold ctermbg=None guibg=None ctermfg='. v
  endfor
endfunction


function! s:everywhere_matches(patts)
  for [k,v] in items(a:patts)
    call matchadd('Note'. k, '\v<('. v .')>:=', 0)
  endfor
endfunction


function! s:everywhere_enable(mode)
  let g:everywhere_activated = a:mode
  augroup everywhere_colors
    autocmd!
    if g:everywhere_activated
      au ColorScheme * call s:everywhere_define(s:colors)
    endif
  augroup END

  augroup everywhere_notes
    autocmd!
    if g:everywhere_activated
      au Syntax * call s:everywhere_matches(s:patterns)
    endif
  augroup END
endfunction


call s:everywhere_define(s:colors)
call s:everywhere_enable(1)
" autocmd WinEnter,VimEnter * call s:everywhere_enable(1)

command! -bar -bang -nargs=0 EverywhereNotesToggle
      \ call s:everywhere_enable(!g:everywhere_activated)
      \ | syntax off | syntax on

nnoremap <unique> <Leader>tT :EverywhereNotesToggle<CR>
