"{{{1 General =====================
fun! SMdef(nm, lhs, rhs, ...)
  call submode#enter_with(a:nm, get(a:, 1, 'n'), get(a:, 2, ''), a:lhs, a:rhs)
endf
fun! SMmap(nm, lhs, rhs, ...)
  call submode#map(a:nm, get(a:, 1, 'n'), get(a:, 2, ''), a:lhs, a:rhs)
endf
command! -nargs=+ SMDEF call SMdef(<f-args>)
command! -nargs=+ SMmap call SMmap(<f-args>)

" Test
" call submode#enter_with('del/x', 'n', '', 'dj', 'dj')
" call submode#map('del/x', 'n', '', 'j', 'dj')
" SM_DEF 'del/x' 'dj' 'dj'
" SM_map 'del/x'  'j' 'dj'
SMDEF del/x dj dj
SMmap del/x  j dj


"{{{1 User-Submodes =====================
" «Smart» x with group undo
nnoremap <silent> <Plug>(fluent-x) :undojoin \| norm! "_x<CR>
call submode#enter_with('fluent/x', 'n', '', 'x', '"_x')
call submode#map('fluent/x', 'n', 'r', 'x', '<Plug>(fluent-x)')
" call submode#leave_with('undo/redo', 'n', '', '<Esc>')


" Undo (chronological) navigation by [g---...]/[g+++...]
call submode#enter_with('undo/redo', 'n', '', 'g-', 'g-')
call submode#enter_with('undo/redo', 'n', '', 'g+', 'g+')
call submode#map('undo/redo', 'n', '', '-', 'g-')
call submode#map('undo/redo', 'n', '', '+', 'g+')


" Switch gt / gT of tab pages by [gttt...]
call submode#enter_with('jump/tab', 'n', '', 'gt', 'gt')
call submode#enter_with('jump/tab', 'n', '', 'gT', 'gT')
call submode#map('jump/tab', 'n', '', 't', 'gt')
call submode#map('jump/tab', 'n', '', 'T', 'gT')


" Window resizing
call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>-')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>+')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '+', '<C-w>-')
call submode#map('winsize', 'n', '', '-', '<C-w>+')


" " File cycling
" call submode#enter_with('nextfile', 'n', 'r', '<Leader>j', '<Plug>(nextfile-next)')
" call submode#enter_with('nextfile', 'n', 'r', '<Leader>k', '<Plug>(nextfile-previous)')
" call submode#map('nextfile', 'n', 'r', 'j', '<Plug>(nextfile-next)')
" call submode#map('nextfile', 'n', 'r', 'k', '<Plug>(nextfile-previous)')


" DEV: Jumping in last changes
call submode#enter_with('jump/chg', 'n', '', '<C-o>', '<C-o>')
call submode#map('jump/chg', 'n', '', 'o', '<C-o>')
call submode#map('jump/chg', 'n', '', 'i', '<C-i>')
call submode#map('jump/chg', 'n', '', 'j', 'g;')
call submode#map('jump/chg', 'n', '', 'k', 'g,')


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
