" vim:fdm=marker:fdl=1

" ================ Sneak =============== {{{1
" USE: Streak-mode features:
"     - automatically jumps to the first match
"         - press <Space> or <Esc> to escape streak-mode
"         - press <Tab> to skip to the next 56 matches
"         - press any key that is _not_ a target label to exit streak-mode and
"           immediately perform that key's normal-mode function
"     - works with all operators, including |surround|
"     - streak-mode edit operations can be repeated and it works correctly
"       regardless of the remaining on-screen matches
"     - s<Enter> repeats the last sneak search (S<Enter> to change direction)
"     - text in |folds| is ignored by streak-mode
"         - you can reach folded/off-screen matches with |;| and |,|
"
" As always, you can:
"     - skip to the next or previous match with |;| or |,|
"     - return to your original location via |CTRL-O| or |``|
"
" Note: If `s` is prefixed with a [count] then |sneak-vertical-scope| is invoked
"       and streak-mode will _not_ be invoked.

" Options: {{{2
let g:sneak#streak = 1
let g:sneak#use_ic_scs = 0
let g:sneak#textobject_z = 0

" nmap <unique> <Space> <Plug>(SneakStreak)


" Sneak: 2-character (default) {{{2
nmap <unique> s <Plug>Sneak_s
xmap <unique> s <Plug>Sneak_s
omap <unique> s <Plug>Sneak_s

nmap <unique> S <Plug>Sneak_S
xmap <unique> S <Plug>Sneak_S
omap <unique> S <Plug>Sneak_S


" Moving: next/prev -- explicit repeat {{{2
" (as opposed to implicit 'clever-s' repeat)
nmap <unique> <Enter> <Plug>SneakNext
xmap <unique> <Enter> <Plug>SneakNext
omap <unique> <Enter> <Plug>SneakNext

nmap <unique> <BS>    <Plug>SneakPrevious
xmap <unique> <BS>    <Plug>SneakPrevious
omap <unique> <BS>    <Plug>SneakPrevious
" OLD:  ]f -> ;  and  [f -> ,

" Standart: 1-character enhanced 'f/t' {{{2
let g:sneak#f_reset = 0
let g:sneak#t_reset = 0

" normal, visual, operator-pending
nmap <unique> f <Plug>Sneak_f
xmap <unique> f <Plug>Sneak_f
omap <unique> f <Plug>Sneak_f

nmap <unique> F <Plug>Sneak_F
xmap <unique> F <Plug>Sneak_F
omap <unique> F <Plug>Sneak_F

nmap <unique> t <Plug>Sneak_t
xmap <unique> t <Plug>Sneak_t
omap <unique> t <Plug>Sneak_t

nmap <unique> T <Plug>Sneak_T
xmap <unique> T <Plug>Sneak_T
omap <unique> T <Plug>Sneak_T


" ============== Surround ============== {{{1
let g:surround_no_mappings=1
"

" Existing: operator-pending analogue (HACK)
nmap <unique> dq <Plug>Dsurround
nmap <unique> cq <Plug>Csurround
" New: add on same line
nmap <unique> yq <Plug>Ysurround
xmap <unique>  q <Plug>VSurround
" New: surround on new lines
nmap <unique> yQ <Plug>YSurround
xmap <unique>  Q <Plug>VgSurround
" New: use whole line
nmap <unique>  Q <Plug>Yssurround
nmap <unique> gQ <Plug>YSsurround

" gs, <C-G>s, <C-G>S -- I can use for my aims!!
" <Plug>Isurround -- unused

if !hasmapto("<Plug>Isurround","i") && "" == mapcheck("<C-S>","i")
  imap <C-S> <Plug>Isurround
endif
