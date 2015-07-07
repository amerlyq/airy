" vim:fdm=marker:fdl=1

if neobundle#tap('vim-sneak')  "{{{1
" USE: Streak-mode features:
"  - automatically jumps to the first match
"    - press <Space> or <Esc> to escape streak-mode
"    - press <Tab> to skip to the next 56 matches
"    - press any key that is _not_ a target label to exit streak-mode and
"      immediately perform that key's normal-mode function
"  - works with all operators, including |surround|
"  - streak-mode edit operations can be repeated and it works correctly
"    regardless of the remaining on-screen matches
"  - s<Enter> repeats the last sneak search (S<Enter> to change direction)
"  - text in |folds| is ignored by streak-mode
"      - you can reach folded/off-screen matches with |;| and |,|
"
" As always, you can:
"     - skip to the next or previous match with |;| or |,|
"     - return to your original location via |CTRL-O| or |``|
"
" Note: If `s` is prefixed with a [count] then sneak-vertical-scope
"   is invoked and streak-mode will _not_ be invoked.

" Options: {{{2
  let g:sneak#streak = 1        " With multiple suggestions use labels to jump
  let g:sneak#use_ic_scs = 1    " Respect 'ignorecase' and 'smartcase'
  let g:sneak#textobject_z = 0  " No default z-operator (I use q-operator)

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
endif


if neobundle#tap('vim-operator-surround')  "{{{1
  nmap <silent><unique> qa <Plug>(operator-surround-append)
  xmap <silent><unique> qa <Plug>(operator-surround-append)

  nmap <silent><unique> qd <Plug>(operator-surround-delete)
  xmap <silent><unique> qd <Plug>(operator-surround-delete)

  nmap <silent><unique> qr <Plug>(operator-surround-replace)
  xmap <silent><unique> qr <Plug>(operator-surround-replace)
"" Chaining of operator+textobj
"   nmap <silent>srr <Plug>(operator-surround-replace)<Plug>(textobj-multiblock-a)
endif

if neobundle#tap('vim-textobj-quotes')  "{{{1
  " Inner quotes are used the most:
  " xmap <silent><unique> q iq
  omap <silent><unique> q iq
endif

" TODO: maybe space/sigil change mappings to reverse -- G/Q?
if neobundle#tap('vim-textobj-space')  "{{{1
  let g:textobj_space_no_default_key_mappings = 1
  xmap <silent><unique> aQ <Plug>(textobj-space-a)
  omap <silent><unique> aQ <Plug>(textobj-space-a)

  xmap <silent><unique> iQ <Plug>(textobj-space-i)
  omap <silent><unique> iQ <Plug>(textobj-space-i)
endif

if neobundle#tap('vim-textobj-sigil')  "{{{1
  let g:textobj_sigil_no_default_key_mappings = 1
  xmap <silent><unique> aG <Plug>(textobj-sigil-a)
  omap <silent><unique> aG <Plug>(textobj-sigil-a)

  xmap <silent><unique> iG <Plug>(textobj-sigil-i)
  omap <silent><unique> iG <Plug>(textobj-sigil-i)
endif
