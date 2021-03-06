" amerlyq/vim-auto-relnum:
"   description: Autotoggle relative/absolute numbers in ruler
"   lazy: 0  # EXPL: enable from the start

" ABSORBED:
"   https://github.com/jeffkreeftmeijer/vim-numbertoggle
" BUG:
"   Disable inside ':<C-f>' CommandLine window

" SEE:DEV: -- consider switching to relative number in operator pending mode
"   'vim-scripts/RelOps'
"   http://www.vim.org/scripts/script.php?script_id=4212
"   http://jeffkreeftmeijer.com/2012/relative-line-numbers-in-vim-for-super-fast-movement/
"   http://vim.1045645.n5.nabble.com/Changing-line-numbers-from-normal-to-relative-td5723150.html
"   http://www.vim.org/scripts/script.php?script_id=4461
"   https://www.reddit.com/r/vim/comments/1hocx4/better_lines_numbers_for_vim/

if exists('g:loaded_auto_relnum') || &cp || v:version < 703 | finish
      \| else | let g:loaded_auto_relnum=1 | endif

let g:arelnum = {'focused': (&number && &rnu) }
let g:arelnum.ignored = {'ft': 'qf', 'preview': 1,
      \ 'buftype': 'help\|nofile\|terminal'}

nnoremap <silent><unique> [Toggle]n  :RelnumToggle<CR>
command! -bar -nargs=0 RelnumToggle  set relativenumber! rnu?
      \| let g:arelnum.focused=&rnu | call <SID>RelnumUpdate(&rnu)

function! s:RelnumUpdate(...)
  if !g:arelnum.focused | return | endif
  if (&l:filetype =~ g:arelnum.ignored.ft) ||
    \(g:arelnum.ignored.preview && &l:previewwindow) ||
    \(&l:buftype =~ g:arelnum.ignored.buftype)
    \| return | endif
  if a:0 > 0 | let &relativenumber = a:1 | endif
  let &numberwidth = max([&g:nuw, 4, 1+strlen(line('w$'))])  " TODO:RFC
endfunc

" BUG: when in insert and do focus in/out -- relativenumber resets!
"       TODO:CHG: save/restore state on out/in
augroup auto_relnum
  autocmd!
  au InsertEnter    * call s:RelnumUpdate(v:insertmode != 'i')
  au InsertLeave    * call s:RelnumUpdate(1)
  au FocusGained    * call s:RelnumUpdate(1)
  au FocusLost      * call s:RelnumUpdate(0)
  au WinEnter       * call s:RelnumUpdate(1)
  au WinLeave       * call s:RelnumUpdate(0)

  " RFC: are all those au necessary? Maybe add/replace some?
  au BufNewFile     * call s:RelnumUpdate()
  au BufReadPost    * call s:RelnumUpdate()
  au FilterReadPost * call s:RelnumUpdate()
  au FileReadPost   * call s:RelnumUpdate()
augroup END
