let g:deoplete#enable_at_startup = 1

" set completeopt+=noinsert
function! s:check_back_space() "{{{
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction "}}}

" Q: I want to use auto select feature like |neocomplete|.
" A: You can use it by the 'completeopt' option. >
" set completeopt+=noinsert

" Q: I want to get quiet messages in auto completion.
" A: You can disable the messages through the 'shortmess' option.
" if has("patch-7.4.314") | set shortmess+=c | endif

"" Use head matcher instead of fuzzy matcher
" call deoplete#custom#set('_', 'matchers', ['matcher_head'])

" <TAB>: completion.
imap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
" imap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ deoplete#mappings#manual_complete()
" <S-TAB>: completion back.
inoremap <expr><S-Tab>  pumvisible() ? "\<C-p>" : "\<C-h>"
" <C-h>, <BS>: close popup and delete backword char.
" TRY: wrap expr in smth to prevent <C-h> from breaking in nvim
inoremap <expr><C-h> (!exists('g:deoplete#_context') ? ''
      \: deoplete#mappings#smart_close_popup()) . "\<C-h>"
inoremap <expr><BS>  (!exists('g:deoplete#_context') ? ''
      \: deoplete#mappings#smart_close_popup()) . "\<BS>"
" inoremap <expr> '  pumvisible() ? deoplete#mappings#close_popup() : "'"

" let g:deoplete#enable_ignore_case = 1
" let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_auto_pairs = 1

" Use head matcher
" call deoplete#custom#set('_', 'matchers', ['matcher_head'])
let g:deoplete#keyword_patterns = {}
" let g:deoplete#keyword_patterns.tex = '\\?[a-zA-Z_]\w*'
let g:deoplete#keyword_patterns.tex = '[^\w|\s][a-zA-Z_]\w*'
