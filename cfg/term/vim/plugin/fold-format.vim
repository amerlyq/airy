" set foldtext=RefinedFoldText()  " ALT getline(v:foldstart)
set foldtext=CustomFoldText('\ ')


"{{{1 Mappings ============================
" Move between folds
noremap <silent><unique> zJ  zj
noremap <silent><unique> zK  zk

" Toggle folds
nnoremap <unique> [Toggle]z :let &foldmethod={'manual': 'syntax',
    \ 'syntax': 'marker', 'marker': 'manual'}[&fdm] \| set fen fdm?<CR>
" nnoremap <unique> [Toggle]z :let &foldmethod=(&fdm=='manual'?'syntax':
"     \ &fdm=='syntax'?'marker': 'manual') \| set foldenable fdm?<CR>
nnoremap <unique> [Toggle]Z :let &fdc=(&fdc?0:2) \| set foldenable! fen?<CR>


"{{{1 IMPL ============================
fun! RefinedFoldText()
  let line = getline(v:foldstart)
  let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
  return '' . v:foldlevel
  ". ' >' . v:folddashes . l:sub
endfun

" Modification of https://github.com/chrisbra/vim_dotfiles/blob/master/plugin/CustomFoldText.vim
" Always show some delimiters (the argument of CustomFoldText) and the tail of
" the folded line, that is, the number of lines folded (absolute and relative)
fun! CustomFoldText(delim)
  let fs = v:foldstart
  while getline(fs) =~ '^\s*$' | let fs = nextnonblank(fs + 1) | endwhile
  if fs > v:foldend | let line = getline(v:foldstart)
  else | let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
  endif
  " Indent foldtext corresponding to foldlevel
  let indent = repeat(' ',shiftwidth())
  let foldLevelStr = repeat(indent, v:foldlevel-1)
  let foldLineHead = substitute(line, '^\s*', foldLevelStr, '')
  " Size foldtext according to window width
  let w = winwidth(0) - 2 - &foldcolumn - (&number ? &numberwidth : 0)
  let foldSize = 1 + v:foldend - v:foldstart
  " Estimate fold length
  let foldSizeStr = " " . foldSize . " lines "
  let lineCount = line("$")
  if has("float")
    try
      let val = (foldSize*1.0) / lineCount*100
      let foldPercentage = printf((val<10?' ':'')."[%.1f%%]", l:val)
    catch /^Vim\%((\a\+)\)\=:E806/	" E806: Using Float as String
      let foldPercentage = printf("[of %d lines] ", lineCount)
    endtry
  endif
  " Build up foldtext
  let foldLineTail = foldSizeStr . foldPercentage
  let lengthTail = strwidth(foldLineTail)
  let lengthHead = w - (lengthTail + 4)
  if strwidth(foldLineHead) > lengthHead
    let foldLineHead = strpart(foldLineHead, 0, lengthHead + 2) . '..'
  endif
  let lengthMiddle = w - strwidth(foldLineHead.foldLineTail)
  " Truncate foldtext according to window width
  let expansionString = repeat(a:delim, lengthMiddle)
  return foldLineHead . expansionString . foldLineTail
endf
