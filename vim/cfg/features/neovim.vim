" WARNING: on Ubuntu chroot may have problems with /usr/bin/python2
" let g:python2_host_prog = '/usr/bin/python2'
let g:python3_host_prog = '/usr/bin/python3'
" let g:python_host_prog = '/usr/bin/python'
" let g:python_host_prog = g:python2_host_prog

" Share the histories
augroup MyAutoCmd
  au CursorHold * if exists(':rshada') | rshada | wshada | endif
augroup END

"" NOTE: t_EI, t_SI, t_SR  doesn't work anymore
try
  "" REF:(-Cursor/lCursor-): :h guicursor
  "  FAIL: colored cursors -- propagation does not work due to !st terminfo
  "  SRC: https://github.com/neovim/neovim/issues/6591
  "  BET:USE: swich cursor color on lang by !st + my-xkblangcolor.patch
  " set guicursor=a:block-Cursor-blinkon0
  " set guicursor+=i-ci-ve:ver25-iCursor
  " set guicursor+=r-cr:hor10-rCursor
  " set guicursor+=o:hor50-oCursor

  " SRC: https://github.com/neovim/neovim/wiki/FAQ#how-can-i-change-the-cursor-shape-in-the-terminal
  " ALT:(a:block): use explicit "n-v-c:block" instead of default fallback
  " BAD:(,o:hor50): partial block not supported by !tmux and !st ※⡟⠌⠊⢨
  set guicursor=a:block-blinkon0,i-ci-ve:ver25,r-cr-o:hor10
  " MAYBE:(blink0): sm:block-blinkwait175-blinkon175-blinkoff150
  "   -blinkwait200-blinkon200-blinkoff150
  "   -blinkwait700-blinkon250-blinkoff400
  "" FIXED: restore cursor shape on exit
  " au MyAutoCmd VimLeave * set guicursor=a:block-blinkon0
catch/E518/|endt

try|set inccommand=split|catch/E518/|endt   " :substitute preview

" BAD: <ESC><ESC> -- consume single <ESC>, sent to client
tnoremap   <C-\><ESC>   <C-\><C-n>

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
  " TRY:CHG: use the same block cursor color in :term as in st(1)
  "   ALSO: https://github.com/neovim/neovim/issues/4696
  " FAIL: don't work :: https://github.com/neovim/neovim/issues/6591
  " hi! Cursor ctermfg=240 ctermbg=255 guifg=#555555 guibg=#eeeeee
endif

" Default home directory.
let t:cwd = getcwd()
