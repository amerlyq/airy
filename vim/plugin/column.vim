"" Selects a column of identical characters {{{1
" Can also be used as a text object for an operator
" On one-line vsel selects a block of identical columns.
" Adopted from ghub:ngn/vim-column

nn <bar> :<c-u>cal<sid>column(0)<cr>
ono<bar> :<c-u>cal<sid>column(0)<cr>
vn <bar> :<c-u>cal<sid>column(1)<cr>
fu! s:column(v) "v:visual mode?
 let[l,c,C]=a:v?[line("'<"),virtcol("'<"),virtcol("'>")]:[line('.'),virtcol('.'),virtcol('.')]
 if a:v&&l!=line("'>")|retu|en "selection must be on a single line
 let n=line('$')|let q='.*\%<'.(c+1).'v\|\%>'.C.'v.*'|let x=substitute(getline(l),q,'','g')
 let i=l-1|wh i>0 &&substitute(getline(i),q,'','g')==#x|let i-=1|endw
 let j=l+1|wh j<=n&&substitute(getline(j),q,'','g')==#x|let j+=1|endw
 cal setpos('.',[0,i+1,len(matchstr(getline(i+1),'.*\%<'.(c+1).'v'))+1,0])|exe"norm!\<c-v>"
 cal setpos('.',[0,j-1,len(matchstr(getline(j-1),'.*\%<'.(C+1).'v'))+1,0])
endf
