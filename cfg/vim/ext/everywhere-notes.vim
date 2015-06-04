" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1

if !has("autocmd") || v:version <= 701 | finish | endif

let s:colors = { 'Err': 1, 'Fix': 9, 'Add': 2, 'Msg': 7, 'Tbd': 5, 'Alt': 3 }

function! s:everywhere_define(cols)
  for [k,v] in items(a:cols)  "guifg=#E01B1B
    exec 'hi! Note'. k .' term=bold,underline cterm=bold,underline ctermbg=None guibg=None ctermfg='. v
  endfor
endfunction

augroup everywhere_colors
  autocmd!
  au ColorScheme * call s:everywhere_define(s:colors)
augroup END

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

let s:patterns = {
      \ 'Err': '\vERR(OR)=|BUG',
      \ 'Fix': '\vFIX(ME)=|WARNING',
      \ 'Add': '\vADD',
      \ 'Msg': '\vNOTE',
      \ 'Tbd': '\vTODO',
      \ 'Alt': '\vALT|OR',
      \ }

function! s:everywhere_matches(patts)
  for [k,v] in items(a:patts)
    call matchadd('Note'. k, v .':=', -1)
  endfor
endfunction

augroup everywhere_notes
  autocmd!
  au Syntax * call s:everywhere_matches(s:patterns)
augroup END
" autocmd WinEnter,VimEnter * :silent! call matchadd('Todo', 'TODO', -1)


call s:everywhere_define(s:colors)
