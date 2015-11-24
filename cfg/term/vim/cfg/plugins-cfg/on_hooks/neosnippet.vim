" Plugin key-mappings.
imap <silent><unique> <C-k>  <Plug>(neosnippet_expand_or_jump)
smap <silent><unique> <C-k>  <Plug>(neosnippet_expand_or_jump)
" imap <silent><unique> L  <Plug>(neosnippet_jump_or_expand)
" smap <silent><unique> L  <Plug>(neosnippet_jump_or_expand)
" xmap <silent><unique> L  <Plug>(neosnippet_start_unite_snippet_target)
" xmap <silent><unique> U  <Plug>(neosnippet_expand_target)

" shougo:
" imap <silent><unique> <C-k>  <Plug>(neosnippet_expand_or_jump)
" smap <silent><unique> <C-k>  <Plug>(neosnippet_expand_or_jump)

" imap <silent><unique> G  <Plug>(neosnippet_expand)
" imap <silent><unique> S  <Plug>(neosnippet_start_unite_snippet)
" xmap <silent><unique> o  <Plug>(neosnippet_register_oneshot_snippet)

inoremap <silent> (( <C-r>=neosnippet#anonymous('\left(${1}\right)${0}')<CR>


"" SuperTab like snippets behavior.
" imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
"     \ "\<Plug>(neosnippet_expand_or_jump)"
"     \: pumvisible() ? "\<C-n>" : "\<TAB>"
" smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
"     \ "\<Plug>(neosnippet_expand_or_jump)"
"     \: "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif


"" ADDITIONAL
" Enable snipMate compatibility feature.
" Theoretically, neosnippet will load snipMate snippets from runtime path automatically.
let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets, like Honza's
let g:neosnippet#snippets_directory='$BUNDLES/vim-snippets/snippets,$VIMHOME/snippets'

" enable the preview window feature in neocomplcache/neocomplete sources
"let g:neosnippet#enable_preview=1

" directory for neosnippet cache
let g:neosnippet#data_directory=expand("$CACHE/neosnippet")
