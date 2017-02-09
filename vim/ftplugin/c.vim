" Set cpp tags file.
"let &l:tags='./tags,tags,'.$DOTVIM.'/tags/cpp/tags'

setl cindent
setl commentstring=//\ %s
setl matchpairs+==:;     " MAYBE useful for C/Java

" Set path.
if has('win32') || has('win64')
    set path+=C:/gcc/i386-pc-mingw32/include
else
    set path+=/usr/local/include;/usr/include
endif
