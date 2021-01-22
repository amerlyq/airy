" @license MIT, (c) amerlyq, 2015

fun! dictl#get(word)
  if (getpos('.') == getpos("'<")) && empty(a:word)
    let word = getline("'<")[getpos("'<")[2] - 1:getpos("'>")[2] - 1]
  else
    let word = empty(a:word) ? expand("<cword>") : a:word
  endif

  let word = substitute(tolower(word), '^\s*\(.\{-}\)\s*$', '\1', '')

  " DONE: dirty impl to add stack items to be able to return back
  "   BUG: adds new entry when "returning forward"
  "     << instead of reusing stack like usual tags do
  let w = winnr()
  let newtag = [{'tagname' : word, 'from' : getpos('.')}]
  call settagstack(w, {'items' : newtag}, 'a')
  call settagstack(w, {'curidx' : gettagstack(w)['length'] + 1})

  " silent! | redraw | echo "Performing lookup for" word "- please wait..."

  silent! exe "noautocmd botright pedit Dict:'" . word . "'"
  noautocmd wincmd P
  setlocal modifiable
  setlocal buftype=nofile ff=dos
  setlocal nobuflisted

  silent! exe "noautocmd r!dict " .shellescape(word). ' | r.dict --filter'

  " OR:(online)
  " silent! exe "noautocmd r!" g:dict_curl_command "-s" g:dict_curl_options "dict://" . host[0] . "/d:" . quoted_word . ":" . db

  setf markdown
  setl concealcursor=nvc
  silent! RetabIndent 2
  silent! exe "%g/^\s*$/d"

  silent! exe "%s/^151 //g"
  silent! exe "%s/^153 //g"
  silent! exe "%s/^\.$/--------------------------------------------------------------------------------/g"
  silent! exe "g/^[0-9][0-9][0-9]/d_"
  silent! exe "1d_"

  if line("$") == 1
    silent! exe "normal! a Nothing found for" quoted_word
  endif

  hi link dictlEngHead PreProc
  call matchadd('dictlEngHead', '\v<[a-zA-Z]+>', -1)
  hi link dictlEngWord Type
  call matchadd('dictlEngWord', '\v<[a-z]+>', -1)

  setlocal nomodifiable
  setlocal nofoldenable
  nnoremap <buffer><silent> q :bw!<CR>
endfun
