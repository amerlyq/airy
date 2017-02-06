if &cp || exists('g:loaded_fold_expr') | finish
else | let g:loaded_fold_expr=1 | endif
let s:cpo_save=&cpo
set cpo&vim

setlocal foldexpr=lh#c#fold#expr(v:lnum)
setlocal foldmethod=expr
setlocal foldtext=lh#c#fold#text()

" command! -b -nargs=0 ShowInstrBegin call lh#c#fold#debug(s:ShowInstrBegin())

" Script Data                                    {{{2
let b:fold_data_begin       = repeat([0], 1+line('$'))
let b:fold_data_instr_begin = deepcopy(b:fold_data_begin)
let b:fold_data_instr_end   = deepcopy(b:fold_data_begin)
let b:fold_data_end         = deepcopy(b:fold_data_begin)
let b:fold_levels           = deepcopy(b:fold_data_begin)
let b:fold_context          = repeat([''], 1+line('$'))

" Mappings {{{1
nnoremap <silent> <buffer> zx :call lh#c#fold#clear('zx')<cr>
nnoremap <silent> <buffer> zX :call lh#c#fold#clear('zX')<cr>

" To help debug
nnoremap <silent> µ :echo lh#c#fold#expr(line('.')).' -- foldlevels:'.string(b:fold_levels[(line('.')-1):line('.')]).' -- @'.line('.').' -- [beg,end;instr_beg,instr_end]:['.b:fold_data_begin[line('.')].','.b:fold_data_end[line('.')].','.b:fold_data_instr_begin[line('.')].','.b:fold_data_instr_end[line('.')].'] --> ctx:'.b:fold_context[line('.')]<CR>


let &cpo=s:cpo_save
