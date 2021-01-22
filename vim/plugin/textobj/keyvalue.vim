""" vim-textobj-keyvalue
" Generalized key/value objects for heterogeneous data (like yaml block style)
" ALT:(https://github.com/vimtaku/vim-textobj-keyvalue) -- works only with vim maps preferably.
if exists('g:loaded_textobj_keyvalue')
  finish
endif

let g:loaded_textobj_keyvalue = 1

" Currently -- only block yaml style
let s:dlm = ':='
fun! s:select_kv(patt)
    normal! 0
    let [bln,bco] = searchpos(a:patt, 'cW',  line('.'))
    let [eln,eco] = searchpos(a:patt, 'cWe', line('.'))
    " let e = getpos('.')
    if !bln || !eln | return | endif
  return ['v', [0, bln, bco, 0], [0, eln, eco, 0]]
endf

" NOTE:DEV: more sense has 'key w/o quotes' and 'key w/' than spaces
" ALSO: how about kv w/-o delimiter?
"   * Add default key-splitter (to work in yaml)
"   * Specify whole list of filetypes on one splitter instead of individually
"   * '=>' delimiters
" FIND: how another plugins do forward-backward
" THINK: if stays on key -- then iv -- it's all right part (even if it's
"   flow style), if on value -- determine level of nesting
"     Maybe chain 'ik' with already existing 'iq'?
" THINK how to exclude inline comments
" THINK where to hold cursor at the end?
fun! s:select_key_i()
  return s:select_kv('\v%(^|\s)\zs[^[:space:]'.s:dlm.']+\ze\s*['.s:dlm.'][[:space:]''"]')
endf
fun! s:select_key_a()
  return s:select_kv('\v\zs(^|\s)[^[:space:]'.s:dlm.']+\s*['.s:dlm.']\ze[[:space:]''"]')
endf
fun! s:select_value_i()
  return s:select_kv('\v['.s:dlm.']\s*\zs[^'.s:dlm.']+\ze\s*')
endf
fun! s:select_value_a()
  return s:select_kv('\v\zs['.s:dlm.']\s*[^'.s:dlm.']+\s*')
endf


call textobj#user#plugin('key', {
\   '-': {
\     '*sfile*': expand('<sfile>:p'),
\     'select-i': 'ik',
\     'select-a': 'ak',
\     '*select-i-function*': 's:select_key_i',
\     '*select-a-function*': 's:select_key_a',
\   }
\})

call textobj#user#plugin('value', {
\   '-': {
\     '*sfile*': expand('<sfile>:p'),
\     'select-i': 'iv',
\     'select-a': 'av',
\     '*select-i-function*': 's:select_value_i',
\     '*select-a-function*': 's:select_value_a',
\   }
\})
