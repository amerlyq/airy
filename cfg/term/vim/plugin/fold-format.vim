if &cp||exists('g:loaded_evfold')|finish|else|let g:loaded_evfold=1|endif
" set foldtext=RefinedFoldText()  " ALT getline(v:foldstart)
set foldtext=CustomFoldText('\ ',1)
let g:fold_extend_preview = 1

" INTEGRATION:
" vim-foldsearch/autoload/foldsearch/foldsearch.vim:224
"   set foldtext=CustomFoldText('\ ',0)
" http://vim.wikia.com/wiki/Customize_text_for_closed_folds


"{{{1 Mappings ============================
" Move between folds
noremap <silent><unique> zJ  zj
noremap <silent><unique> zK  zk
" Focus the current fold by closing all others
nnoremap <silent><unique> ZZ mzzM`zzv

" Toggle folds
nnoremap <unique> [Toggle]z :let &foldmethod=get({'manual': 'syntax',
    \ 'syntax': 'marker', 'marker': 'manual'}, &fdm, 'manual') \| set fen fdm?<CR>
" nnoremap <unique> [Toggle]z :let &foldmethod=(&fdm=='manual'?'syntax':
"     \ &fdm=='syntax'?'marker': 'manual') \| set foldenable fdm?<CR>
nnoremap <unique> [Toggle]Z :let &fdc=(&fdc?0:2) \| set foldenable! fen?<CR>
nnoremap <unique> [Toggle]e :let g:fold_extend_preview=!g:fold_extend_preview<CR>

fun! ParsFoldLevel(lnum)
  return ( getline(a:lnum) =~ '^\s*$' && getline(a:lnum + 1) =~ '\S'
         \ ? '<1' : 1 )
endf
comm! FoldPars set foldmethod=expr foldexpr=ParsFoldLevel(v:lnum)

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
" XXX: slow on big files! -- seems like by my nextnonblank features!
" TODO: tabs has bad clearness in crumpled *.c -- use digit at beginning
" -- THINK: embed digit directly in foldcolumn? -- instead of default '+' for all
" THINK: toggle highlight for folds -- more/less visible? Like Folded/Comment
" DEV: collapse all block text in one line if len(s) is less then empty width

fun! CustomFoldText(delim, preview)
  let fs = v:foldstart
  let line=''

  if a:preview
    if getline(fs) =~ '^\s*$'
      let fs = nextnonblank(fs + 1)
    endif
    let nsp = indent(fs)

    " FIXME: duplicates header instead of merging fold zones
    " if getline(fs) =~ '^\s*{\s*$'| let fs = prevnonblank(fs - 1) | endif
    " let &v:foldstart = l:fs-1  # BUG: don't work?

    if g:fold_extend_preview
      if getline(fs) =~ '^\s*{\s*$'
        let line = '{  '  " . repeat(' ', &tabwidth)
        let fs = nextnonblank(fs + 1)
      endif
    endif

    if fs == 0 || fs > v:foldend
      let fs = v:foldstart
      let nsp = indent(fs)
    endif

    let line .= substitute(getline(fs), '^\s\+', '', 'g')
  else
    let nsp = 0
  endif

  " Indent foldtext corresponding to foldlevel
  " let foldLevelStr = repeat(repeat(' ',shiftwidth()), v:foldlevel-1)
  " let foldLineHead = substitute(line, '^\s*', foldLevelStr, '')

  " SEE: \u2056 \ufbb8 \u272b
  let m="\u2056"   " TODO: set through variable. Reuse airline symbs?
  if nsp <= 1
    let foldLineHead = l:m . l:line
  else
    let lm = (v:foldlevel <= 1 ? l:m : string(v:foldlevel))
    let foldLineHead = l:lm . repeat(' ', nsp-2). l:m . l:line
  endif

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



":[range]RenderClosedFolds
"   Replace all lines currently hidden inside closed folds
"   with a single line representing 'foldtext'.
" http://stackoverflow.com/questions/30583388/how-can-i-save-in-vim-a-file-with-the-actual-fold-text-43-lines
fun! s:RenderClosedFolds()
  if line('.') == foldclosed('.')
    let l:result = foldtextresult('.')
    call setline('.', l:result)
    execute printf('syntax match renderedFold "\V\^%s\$" containedin=ALL keepend', escape(l:result, '"\'))
  else
    delete _
  endif
endf

fun! s:ToggleRenderClosedFolds(line1, line2)
  hi def link renderedFold Folded
  let l:entire = (a:line1 == 1 && a:line2 == line('$'))
  if l:entire| syntax clear renderedFold |en
  let l:fdm = &l:foldmethod
  setlocal foldmethod=manual
  try
    exe a:line1.','.a:line2.'folddoclosed call <SID>RenderClosedFolds()'
  finally
    if l:entire| setlocal nofoldenable |en
    let &l:foldmethod = l:fdm
  endtry
endf

command! -bar -range=% RenderClosedFolds
    \ call s:ToggleRenderClosedFolds(<line1>, <line2>)
