"let g:easytags_async=1
"By changing it to 'always' you're telling vim-easytags to sacrifice accuracy in order to gain performance.
"let g:easytags_syntax_keyword = 'auto'

"" === Where to save ===
"let g:easytags_file = $VIMCACHEDIR . '/easytags'
let g:easytags_by_filetype = $VIMCACHEDIR . '/easytags.d'
" Use local tags files (and update them instead) if exists
" set tags=./tags;
" let g:easytags_dynamic_files = 1

