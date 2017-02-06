" DEPRECATED: by 'vim-asterisk'

" use ag for recursive searching so we don't find 10,000 useless hits inside node_modules
nnoremap <leader>* :call ag#Ag('grep', '--literal '
    \ . shellescape(expand("<cword>")))<CR>
vnoremap <leader>* :<C-u>call VisualStarSearchSet('/', 'raw')<CR>
    \ :call ag#Ag('grep', '--literal ' . shellescape(@/))<CR>
