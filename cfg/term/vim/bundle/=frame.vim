let s:leader = g:mapleader | let mapleader = "\\"  "{{{

if neobundle#tap('DrawIt')
  map <unique> <Leader>DI <Plug>DrawItStart
  map <unique> <Leader>DS <Plug>DrawItStop
  map <unique> <Leader>Dsw <Plug>SaveWinPosn
  map <unique> <Leader>Drw <Plug>RestoreWinPosn
endif

" Change working directory to that of the current file
noremap <unique> <silent> <Leader>cw :lcd %:p:h \| pwd<CR>

if neobundle#tap('vim-rooter')
  let g:rooter_manual_only = 1
  let g:rooter_disable_map = 1
  nnoremap <unique> <silent> <Leader>cd :Rooter<CR>
endif


if neobundle#tap('linediff.vim')
  nnoremap <unique> <Leader>L  :LinediffReset<CR>
  vnoremap <unique> <Leader>L  :Linediff<CR>
endif

if neobundle#tap('zeavim.vim')  " {{{1
  let g:zv_disable_mapping = 1
  nmap <unique> <silent> <Leader>z <Plug>Zeavim
  vmap <unique> <silent> <Leader>z <Plug>ZVVisSelection
  nmap <unique> <silent> <Leader>Z <Plug>ZVKeyDocset
  nmap <unique> <silent> <Leader><Leader>z <Plug>ZVKeyword
  " let g:zv_file_types = {'python' : 'python 3'}
  " let g:zv_docsets_dir = has('unix') ?
  "             \ '~/Important!/docsets_Zeal/' :
  "             \ 'Z:/myUser/Important!/docsets_Zeal/'
endif

let mapleader = s:leader  " }}}



if neobundle#tap('NrrwRgn')  " NrrwRgn: {{{1
":: Focus on content in split window
  " Create two region buffers and use :diffthis --> instead of LineDiff
  " Multiselection in new buffer! :v/^#/NRP | NRM
  " Tip -- completely delete blocks you don't want to change.

  " let g:nrrw_rgn_nohl = 1
  " split buffer in same window
  let g:nrrw_topbot_leftright = 'botright'
  nmap <unique> <Leader>n <Plug>NrrwrgnDo
  xmap <unique> <Leader>n <Plug>NrrwrgnDo
  omap <unique> <Leader>n <Plug>NrrwrgnDo
  " separate buffer
  nmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  xmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  omap <unique> <Leader>N <Plug>NrrwrgnBangDo
endif


if neobundle#tap('vim-altr')  " vim-altr: {{{1
":: Toggle between alternative files (.h, .cpp, ...)
  nmap <unique> ]f  <Plug>(altr-forward)
  nmap <unique> [f  <Plug>(altr-back)
  command! A  call altr#forward()
  " Additional rules
  call altr#define('%/src/%.c', '%/inc/%.h')
  " ALT: map <F4> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
endif

if neobundle#tap('vim-smooth-scroll')  " {{{1
  noremap <silent> <unique> <C-u> :<C-u>call smooth_scroll#up(&scroll, 0, 2)<CR>
  noremap <silent> <unique> <C-d> :<C-u>call smooth_scroll#down(&scroll, 0, 2)<CR>
  noremap <silent> <unique> <C-b> :<C-u>call smooth_scroll#up(&scroll*2, 0, 4)<CR>
  noremap <silent> <unique> <C-f> :<C-u>call smooth_scroll#down(&scroll*2, 0, 4)<CR>
endif

if neobundle#tap('vim-signature')  " {{{1
  let g:SignatureIncludeMarkers = '!@#$%^&*()[]".'
  let g:SignaturePurgeConfirmation = 1
  let g:SignaturePrioritizeMarks = 0
endif
