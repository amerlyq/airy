" WARNING: on Ubuntu chroot may have problems with /usr/bin/python2
let g:python2_host_prog = '/usr/bin/python2'
let g:python3_host_prog = '/usr/bin/python3'
let g:python_host_prog = g:python2_host_prog

" SEE :h guicursor for -Cursor/lCursor-
"   https://github.com/neovim/neovim/wiki/FAQ#how-can-i-change-the-cursor-shape-in-the-terminal
try|set guicursor=a:block-Cursor/lCursor-blinkon0
  \,i-ci-ve:ver25,r-cr:hor10,o:hor50
  " \n-v-c:block-Cursor/lCursor-blinkon0
  " \,sm:block-blinkwait175-blinkoff150-blinkon175
  " \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
  " BAD:('tmux/st' have no support for percentage or blink or color?):
  "   o:hor50
  "   o:block-ErrorMsg
  "   o:block-blinkwait200-blinkoff200-blinkon200
  "" FIXED: restore cursor shape on exit
  " au MyAutoCmd VimLeave * set guicursor=a:block-blinkon0
catch/E518/|endt

try|set inccommand=split|catch/E518/|endt   " :substitute preview

" BAD: <ESC><ESC> -- consume single <ESC>, sent to client
tnoremap   <C-\><ESC>   <C-\><C-n>

" Share the histories
augroup MyAutoCmd
  au CursorHold * if exists(':rshada') | rshada | wshada | endif
augroup END

" SEE: https://github.com/neovim/neovim/issues/2897#issuecomment-115464516
" Terminal base colors used by UIs with RGB capabilities (other use predefined)
if has('termguicolors') || exists('$NVIM_TUI_ENABLE_TRUE_COLOR')
  let g:terminal_color_0  = '#2e3436'
  let g:terminal_color_1  = '#cc0000'
  let g:terminal_color_2  = '#4e9a06'
  let g:terminal_color_3  = '#c4a000'
  let g:terminal_color_4  = '#3465a4'
  let g:terminal_color_5  = '#75507b'
  let g:terminal_color_6  = '#0b939b'
  let g:terminal_color_7  = '#d3d7cf'
  let g:terminal_color_8  = '#555753'
  let g:terminal_color_9  = '#ef2929'
  let g:terminal_color_10 = '#8ae234'
  let g:terminal_color_11 = '#fce94f'
  let g:terminal_color_12 = '#729fcf'
  let g:terminal_color_13 = '#ad7fa8'
  let g:terminal_color_14 = '#00f5e9'
  let g:terminal_color_15 = '#eeeeec'
endif

" Default home directory.
let t:cwd = getcwd()
