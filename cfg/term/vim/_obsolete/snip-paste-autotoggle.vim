if &term !~# 'xterm|urxvt' | finish | endif
" THINK urxvt inserts text by this mode?
"   SEE more at
"       https://github.com/ConradIrwin/vim-bracketed-paste/blob/master/plugin/bracketed-paste.vim
" WARNING need to save/restore &cpo and control its flag to allow "\<Esc>" interpretation
" THINK DEPRECATED?
"   I have no use of it, having own '+' mappings and urxvt shortcuts
"   Also, keymap clashes with <Esc> presses in INSERT when 'notimeout' set
"   WARNING Don't use 'au InsertEnter * set paste' as <CR> will never indent!

"Auto paste-toggle w/o <F2>
" http://www.linux.org.ru/forum/desktop/9146271

"Extended tmux-version
function! WrapForTmux(s)
  if !exists('$TMUX')
    return a:s
  endif

  let tmux_start = "\<Esc>Ptmux;"
  let tmux_end = "\<Esc>\\"

  return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
endfunction

let &t_SI .= WrapForTmux("\<Esc>[?2004h")
let &t_EI .= WrapForTmux("\<Esc>[?2004l")

" OR let &pastetoggle = "\e[201~"
set pastetoggle=<Esc>[201~

function! XTermPasteBegin(ret)
  set paste
  return a:ret
endfunction

noremap <special> <expr> <Esc>[200~ XTermPasteBegin('0i')
inoremap <special> <expr> <Esc>[200~ XTermPasteBegin('')
cnoremap <special> <Esc>[200~ <nop>
cnoremap <special> <Esc>[201~ <nop>

" Optimize vertical split.
" Note: Newest terminal is needed.
" let &t_ti .= "\e[?6;69h"
" let &t_te .= "\e7\e[?6;69l\e8"
" let &t_CV = "\e[%i%p1%d;%p2%ds"
" let &t_CS = "y"

" Change cursor shape.
if &term =~ "xterm"
  let &t_SI = "\<Esc>]12;lightgreen\x7"
  let &t_EI = "\<Esc>]12;white\x7"
endif
