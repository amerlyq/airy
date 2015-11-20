"{{{1 Common/Define =====================
fun! SMdef(nm, lhs, rhs, ...)
  call submode#enter_with(a:nm, get(a:, 1, 'n'), get(a:, 2, ''), a:lhs, a:rhs)
endf
fun! SMmap(nm, lhs, rhs, ...)
  call submode#map(a:nm, get(a:, 1, 'n'), get(a:, 2, ''), a:lhs, a:rhs)
endf
command! -nargs=+ SMDEF call SMdef(<f-args>)
command! -nargs=+ SMmap call SMmap(<f-args>)


"{{{1 User-Submodes =====================
" «Smart» x with group undo (REF: http://haya14busa.com/improve-x-with-vim-submode/)
SMDEF fluent/x  x "_x
SMmap fluent/x  x <Plug>(fluent-x) n r
nnoremap <silent> <Plug>(fluent-x) :undojoin \| norm! "_x<CR>


" Undo (chronological) navigation by [g---...]/[g+++...]
SMDEF undo/redo  g- g-
SMDEF undo/redo  g+ g+
SMmap undo/redo  -  g-
SMmap undo/redo  +  g+


" Switch gt / gT of tab pages by [gttt...]
SMDEF jump/tab  gt gt
SMDEF jump/tab  gT gT
SMmap jump/tab  t  gt
SMmap jump/tab  T  gT


" Window resizing
SMDEF winsize  <C-w>>  <C-w>>
SMDEF winsize  <C-w><  <C-w><
SMDEF winsize  <C-w>+  <C-w>-
SMDEF winsize  <C-w>-  <C-w>+
SMmap winsize       >  <C-w>>
SMmap winsize       <  <C-w><
SMmap winsize       +  <C-w>-
SMmap winsize       -  <C-w>+


" " File cycling
" SMDEF nextfile r  <Leader>j <Plug>(nextfile-next)
" SMDEF nextfile r  <Leader>k <Plug>(nextfile-previous)
" SMmap nextfile r  j <Plug>(nextfile-next)
" SMmap nextfile r  k <Plug>(nextfile-previous)


" DEV: Jumping in last changes
SMDEF jump/chg  <C-o>  <C-o>
SMmap jump/chg      o  <C-o>
SMmap jump/chg      i  <C-i>
SMmap jump/chg      j  g;
SMmap jump/chg      k  g,


" Move a tab page in the <Space> gttt...
function! s:SIDP()
  return '<SNR>' . matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SIDP$') . '_'
endfunction
function! s:movetab(nr)
  execute 'tabmove' g:V.modulo(tabpagenr() + a:nr - 1, tabpagenr('$'))
endfunction
let s:movetab = ':<C-u>call ' . s:SIDP() . 'movetab(%d)<CR>'
call submode#enter_with('movetab', 'n', '', '<Space>gt', printf(s:movetab, 1))
call submode#enter_with('movetab', 'n', '', '<Space>gT', printf(s:movetab, -1))
call submode#map('movetab', 'n', '', 't', printf(s:movetab, 1))
call submode#map('movetab', 'n', '', 'T', printf(s:movetab, -1))
unlet s:movetab
