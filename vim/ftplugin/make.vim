" HACK:(deoplete): use spaces in Makefile
" au FileType make :imap <buffer><silent><expr>  <TAB>  pumvisible() ? "\<C-n>"
"   \: (virtcol(".")==1 ? "\<TAB>" : repeat(' ', &tabstop - ((virtcol('.') - 1) % &tabstop)))

setlocal noexpandtab
setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
