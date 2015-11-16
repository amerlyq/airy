"---------------------------------------------------------------------------
" neosnippet.vim
"

smap <silent>L     <Plug>(neosnippet_jump_or_expand)
xmap <silent>L     <Plug>(neosnippet_start_unite_snippet_target)
imap <silent>K     <Plug>(neosnippet_expand_or_jump)
smap <silent>K     <Plug>(neosnippet_expand_or_jump)
imap <silent>G     <Plug>(neosnippet_expand)
imap <silent>S     <Plug>(neosnippet_start_unite_snippet)
xmap <silent>o     <Plug>(neosnippet_register_oneshot_snippet)
xmap <silent>U     <Plug>(neosnippet_expand_target)

imap <silent>L     <Plug>(neosnippet_jump_or_expand)

let g:neosnippet#enable_snipmate_compatibility = 1

" let g:snippets_dir = '~/.vim/snippets/,~/.vim/bundle/snipmate/snippets/'
let g:neosnippet#snippets_directory = '~/.vim/snippets'

inoremap <silent> (( <C-r>=neosnippet#anonymous('\left(${1}\right)${0}')<CR>
