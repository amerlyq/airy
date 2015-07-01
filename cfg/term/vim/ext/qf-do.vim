" SEE: another snippet
"   https://github.com/henrik/vim-qargs

" USAGE:
"   :Ggrep findme
"   :Qargs
"   :argdo %s/findme/replacement/gc
"   :argdo update
" Or you could join the last 3 commands together in a single line:
"   :Ggrep findme
"   :Qargs | argdo %s/findme/replacement/gc | update

" ALT:
"   :args `git grep -l findme`
"   :argdo %s/findme/replacement/gc
"   :argdo update

command! -nargs=0 -bang -bar Qargs call s:SetArgs(QuickfixFilenames(), <bang>1)

function! QuickfixFilenames()
  " Building a hash ensures we get each buffer only once
  let buffer_numbers = {}
  for quickfix_item in getqflist()
    let bufnr = quickfix_item['bufnr']
    " Lines without files will appear as bufnr=0
    if bufnr > 0
      let buffer_numbers[bufnr] = bufname(bufnr)
    endif
  endfor
  return join(map(values(buffer_numbers), 'fnameescape(v:val)'))
endfunction

function! s:SetArgs(args, jump_to_first)
  if len(a:args) > 0
    0,1000argdelete
    execute 'argadd '. a:args
    if a:jump_to_first
      argument
    endif
  endif
endf

" ALT:
"   https://github.com/Peeja/vim-cdo
"   https://github.com/sk1418/QFGrep
"   https://github.com/stefandtw/quickfix-reflector.vim
"   https://github.com/jceb/vim-editqf

function! s:FilterQuickfixList(bang, pattern)
  let cmp = a:bang ? '!~#' : '=~#'
  call setqflist(filter(getqflist(), "bufname(v:val['bufnr']) " . cmp . " a:pattern"))
endfunction
command! -bang -nargs=1 -complete=file QFilter call s:FilterQuickfixList(<bang>0, <q-args>)

" vim:et:sw=2:ts=4:tw=78
