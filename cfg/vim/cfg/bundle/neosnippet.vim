" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
    \ "\<Plug>(neosnippet_expand_or_jump)"
    \: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
    \ "\<Plug>(neosnippet_expand_or_jump)"
    \: "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif


"" ADDITIONAL
" Enable snipMate compatibility feature.
" Theoretically, neosnippet will load snipMate snippets from runtime path automatically.
"let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets, like Honza's
let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets,~/.vim/snippets'

" enable the preview window feature in neocomplcache/neocomplete sources
"let g:neosnippet#enable_preview=1

" directory for neosnippet cache
let g:neosnippet#data_directory=expand("~/.cache/vim/neosnippet")
