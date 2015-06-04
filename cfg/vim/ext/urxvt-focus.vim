" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
" @brief: Integration with term to receive focus events in vim
" @ref: MIT, (c) amerlyq, 2015

" TODO:
"   think about how to disable those commands (or make them not harmful) if plugin is absent
"   http://karma-lab.net/creer-plugin-term-sauvegarder-vim-automatiquement
" TODO:
"   http://vimdoc.sourceforge.net/htmldoc/term.html#t_RV
"   https://github.com/tmux-plugins/vim-tmux-focus-events
" TODO:
"   read vitality.txt

" || &term !~ 'rxvt'  -- why by default it is 'xterm' ?
if has('gui_running') || &cp || version < 700 ||
      \ (exists('g:did_term_focus') && g:did_term_focus) | finish | endif
let g:did_term_focus = 1


let s:inside_iterm = exists('$ITERM_PROFILE')
let s:inside_tmux = exists('$TMUX')


function s:tmux_wrap(s)
    return "\<Esc>Ptmux;" . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . "\<Esc>\\"
endfunction


function! s:term_cso(mode)
  exec 'silent !echo -ne "\033]777;focus;' . a:mode . '\007"'
endfunction


function! s:term_modes()
  " For iTerm2
  let enable_focus_reporting  = "\<Esc>[?1004h"
  let disable_focus_reporting = "\<Esc>[?1004l"
  let cursor_to_bar   = "\<Esc>]50;CursorShape=1\x7"
  let cursor_to_block = "\<Esc>]50;CursorShape=0\x7"
  " These sequences save/restore the screen.
  let save_screen    = "\<Esc>[?1049h"
  let restore_screen = "\<Esc>[?1049l"

  " Install focus autohooks
  let &t_ti = cursor_to_block . enable_focus_reporting . save_screen
  let &t_te = disable_focus_reporting . restore_screen

  " Install insert mode autohooks
  let s:old_SI=&t_SI | let &t_SI = cursor_to_bar
  let s:old_EI=&t_EI | let &t_EI = cursor_to_block
endfunction


function! s:enable_focus_events(state)
  augroup term_focus
    autocmd!
    if a:state
      au VimEnter    * call s:term_cso('on')
      au VimLeavePre * call s:term_cso('off')
    endif
  augroup END
endfunction


function s:do_in_cmd(cmd)
  let cmd = getcmdline()
  let pos = getcmdpos()
  exec a:cmd
  call setcmdpos(pos)
  return cmd
endfunction


function! s:map_all_modes(keys, mid, cmds)
  let kmd = ['n', 'o', 'x', 'i', 'c']
  let beg = 'noremap <silent> <unique> '
  let prf = ['', '<Esc>', '<Esc>', '<C-o>', '<C-\>e<SID>do_in_cmd("']
  for m in range(len(kmd))
    if 'c'==kmd[m] | let mid=a:mid | let end=' %")'
    else | let mid=':'.a:mid | let end=' %<CR>' | endif
    if 'x'==kmd[m] | let end.='gv'  | endif
    for i in range(len(a:keys))
      exec kmd[m].beg. a:keys[i].' '.prf[m].mid. a:cmds[i] .end
    endfor
  endfor
endfunction


function! s:term_init()
  let keys = ['<F24>', '<F25>']   " Up to <F37>
  " Use modern xterm codes (or create your own: ^[[UlFocusIn, ^[[UlFocusOut)
  let codes = ["\<Esc>[I", "\<Esc>[O"]
  for i in range(len(keys)) | exec 'set '.keys[i].'='.codes[i] | endfor
  call s:map_all_modes(keys, 'silent doau ', ['FocusGained', 'FocusLost'])
  call s:enable_focus_events(1)
endfunction


function! s:term_exit()
  " Install insert mode autohooks
  let s:old_SI=&t_SI | let &t_SI = cursor_to_bar
  let s:old_EI=&t_EI | let &t_EI = cursor_to_block
endfunction

call s:term_init()

" ERROR: don't work?
" autocmd VimEnter * call s:term_init()
" autocmd VimLeave * call s:term_exit()


" TESTING {{{
autocmd! FocusGained * set number
autocmd! FocusLost * set nonumber

" Reload all changed, save all unchanged
" map   :bufdo checktime<CR>
" map   :wa!<CR>


" if g:term_focus_enable
" endif
" if g:term_focus_keymap
" endif
