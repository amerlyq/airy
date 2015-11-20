" amerlyq/vim-auto-relnum:
"   description: Autotoggle relative/absolute numbers in ruler
"   lazy: 0  # EXPL: enable from the start

if exists('g:loaded_auto_relnum') || &cp || v:version < 703
\| finish | else | let g:loaded_auto_relnum=1 | endif

nnoremap <unique> <Leader>tn  :setl number relativenumber! rnu?
      \\|call s:RelativeNumUpdate(&rnu)<CR>

let b:auto_relnum_enabled = 1
let b:auto_relnum_focused = 1

function! s:RelNumUpdate(...)
  if a:0 > 0 | let b:auto_relnum_enabled = a:1 | endif
  if !b:auto_relnum_enabled || !(&number || &relativenumber)
    return | endif
  let &l:relativenumber = (b:auto_relnum_focused && v:insertmode == 'i')
  let &l:numberwidth = max([&g:nuw, 4, 1+len(line('$'))])
endfunc

augroup MyAutoCmd
  au BufNewFile     * call s:RelNumUpdate(1)
  au BufReadPost    * call s:RelNumUpdate()
  au FilterReadPost * call s:RelNumUpdate()
  au FileReadPost   * call s:RelNumUpdate()

  au InsertEnter    * call s:RelNumUpdate(0)
  au InsertLeave    * call s:RelNumUpdate(1)

  au FocusLost      * call s:RelNumUpdate(0)
  au FocusGained    * call s:RelNumUpdate(1)
  au WinLeave       * call s:RelNumUpdate(0)
  au WinEnter       * call s:RelNumUpdate(1)
augroup END
