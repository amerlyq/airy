" TODO: merge with ~/.cache/vim/dein/repos/github.com/rstacruz/vim-xtract/plugin/xtract.vim
" USAGE: :'<,'>Extract newfile

noremap <LocalLeader>> :Extract<Space>

command! -range -bang -nargs=1 -complete=file  Extract
      \ :<line1>,<line2>call extract#main(<bang>0, <f-args>)


fun! extract#vlines()
  let [lbeg, cbeg] = getpos("'<")[1:2]
  let [lend, cend] = getpos("'>")[1:2]
  let lines = getline(lbeg, lend)
  if len(lines) == 0
      return ''
  endif
  let lines[-1] = lines[-1][: cend - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][cbeg - 1:]
  return lines
endf

function! extract#main(bang, nm) range abort
  let rel = a:nm
  if fnamemodify(a:nm,':e') ==# ''
    let ext = expand('%:e')
    if ext !=# ''| let rel.= '.'.ext |en
  en
  let path = expand('%:h').'/'.rel

  if filereadable(path) && !a:bang
    echoe 'E13: File exists (add ! to override): '.path
    return
  endif

  " ALT: silent exe a:firstline.",".a:lastline . "yank"
  let xa = xtref#new()
  let xr = xtref#invert(xa)
  let lines = extract#vlines()

  " NOTE: strip from all lines common min indent TODO: replace '\t' => ' 'x2
  let mindent = min(map(copy(lines),'len(matchstr(v:val, "^\\s*"))'))
  let @x = join(['# '.xa, ''] + map(lines, 'strpart(v:val, mindent)'), "\n")

  let dir = fnamemodify(path, ':h')
  if !isdirectory(dir)| call mkdir(dir, 'p') |en
  " call writefile(lines, path)

  " THINK: keep first line of selected block together/instead path to excerpt
  " TODO: also generate backref
  " FIND: vim excerpt, etc. e.g. ※[!^nu
  " ALT: '<,'>s/\%V\zs\_.*\ze\%V//g
  let indent = matchstr(getline(a:firstline),'^\s*')
  let link = './'.rel.' '.xr
  let backref = substitute(&commentstring, '%s', link, '')  " indent .
  sil exe 'norm! :'.a:firstline.','.a:lastline ."change\<CR>". backref ."\<CR>.\<CR>"
  " sil exe a:firstline.','.a:lastline ."change\<CR>". backref ."\<CR>.\<CR>"
  " sil exe "'<,'>change\<CR>". backref ."\<CR>.\<CR>"

  sil exe 'split '.path
  put x
  1
  normal "_dd
  " silent! '%s#\($\n\s*\)\+\%$##'
  " silent 1
  StripLines
endfunction
