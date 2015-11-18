"{{{1 Motions ============================
if neobundle#tap('matchit.zip') "{{{
  function! neobundle#hooks.on_post_source(bundle)
    silent! execute 'doautocmd Filetype' &filetype
  endfunction

  call neobundle#untap()
endif "}}}

if neobundle#tap('vim-sneak') "{{{
"  - s<Enter> repeats (even off-screen), <Tab> skips to next 56 matches,
"  - any key that is _not_ a target label, performs its normal-mode function
"  - text in |folds| is ignored by streak-mode
"  - return to your original location via |CTRL-O| or |``|
"  - if `s` is prefixed with a [count] then sneak-vertical-scope invoked
  let g:sneak#streak = 1        " Use labels, Space/Esc to choose current
  let g:sneak#s_next = 1        " Use s/S immediately after sneak to next/prev
  let g:sneak#f_reset = 0
  let g:sneak#t_reset = 0
  let g:sneak#use_ic_scs = 1    " Respect 'ignorecase' and 'smartcase'
  let g:sneak#textobject_z = 0  " No default z-operator (I use q-operator)
  if hasmapto('[Space]') | let g:sneak#streak_esc = '[Space]' | endif

  " SEARCH sneak 's' -- 2-char (default) and clever-'f/t' -- 1-char enhanced
  for c in split('sfFtT', '\zs')
    call Map_nxo(c, '<Plug>Sneak_'. c)
  endfor
  " JUMP next/prev -- explicit repeat (as opposed to implicit 'clever-s')
  call Map_nxo('<Enter>', '<Plug>SneakNext')
  call Map_nxo('<BS>',    '<Plug>SneakNext')
  " BUG JUMP by label (as in browser) -- how to configure?
  call Map_nxo('[Frame]s', '<Plug>(SneakStreak)')
  call Map_nxo('[Frame]S', '<Plug>(SneakStreakBackward)')

  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-expand-region') "{{{
  xmap v <Plug>(expand_region_expand)
  xmap <C-v> <Plug>(expand_region_shrink)
  call neobundle#untap()
endif "}}}


"{{{1 Operators ============================
if neobundle#tap('vim-operator-surround')  "{{{
  nmap <silent><unique> [Quote]a <Plug>(operator-surround-append)
  xmap <silent><unique> [Quote]a <Plug>(operator-surround-append)
  " TRY Insert around one character only
  nmap <silent><unique> [Quote]<Space> [Quote]al

  nmap <silent><unique> [Quote]d <Plug>(operator-surround-delete)
  xmap <silent><unique> [Quote]d <Plug>(operator-surround-delete)

  nmap <silent><unique> [Quote]r <Plug>(operator-surround-replace)
  xmap <silent><unique> [Quote]r <Plug>(operator-surround-replace)
  call neobundle#untap()

  if neobundle#tap('vim-textobj-anyblock')  "{{{
    " Current enclosing block of ({["'<`
    nmap <silent><unique> [Quote]b <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
    nmap <silent><unique> [Quote]B <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
    " Surrounding symbols for current cursor position (like 'f`')
    nmap <silent><unique> [Quote]f <Plug>(operator-surround-replace)<Plug>(textobj-between-a)
    nmap <silent><unique> [Quote]F <Plug>(operator-surround-delete)<Plug>(textobj-between-a)
    " Explicit shortcuts
    nmap <silent><unique> [Quote]Q <Plug>"operator-surround-delete"<Plug>(textobj-anyblock-a)"
    " for c in [['('], ['0', '('], ['{'], ['9', '{'], ['['],
    " \ ['q', '"'], ['"'], ["'"], ['<'], ['.', '<'], ['`']]
    "   exe printf("nmap <silent><unique> [Quote]%s <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)%s",
    "       \ string(c[0]), string(1<len(c)? c[1] : c))
    " endfor
    nmap <silent><unique> [Quote]( <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)(
    nmap <silent><unique> [Quote]{ <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a){
    nmap <silent><unique> [Quote][ <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)[
    nmap <silent><unique> [Quote]' <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)'
    nmap <silent><unique> [Quote]< <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)<
    nmap <silent><unique> [Quote]` <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)`
    call neobundle#untap()
  endif "}}}
endif "}}}


if neobundle#tap('vim-operator-replace') "{{{
  " THINK Could be used instead of my own paste-replace?
  " xmap p <Plug>(operator-replace)
  map - <Plug>(operator-replace)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-entire')  "{{{
  let g:textobj_entire_no_default_key_mappings = 1
  xmap <silent><unique> aG <Plug>(textobj-entire-a)
  omap <silent><unique> aG <Plug>(textobj-entire-a)
  xmap <silent><unique> iG <Plug>(textobj-entire-i)
  omap <silent><unique> iG <Plug>(textobj-entire-i)
  call neobundle#untap()
endif "}}}


"{{{1 Textobj ============================
if neobundle#tap('vim-textobj-syntax')  "{{{
  let g:textobj_syntax_no_default_key_mappings = 1
  " ATTENTION currently textobj-syntax-a acts the same as textobj-syntax-i
  xmap <silent><unique> ah <Plug>(textobj-syntax-a)
  omap <silent><unique> ah <Plug>(textobj-syntax-a)
  xmap <silent><unique> ih <Plug>(textobj-syntax-i)
  omap <silent><unique> ih <Plug>(textobj-syntax-i)
  call neobundle#untap()
endif "}}}


if neobundle#tap("vim-textobj-quotes")  "{{{
  " Outer quoted is the most useful:
  " omap <silent><unique> [Quote] aq
  call neobundle#untap()
endif "}}}


" TODO: maybe space/sigil change mappings to reverse -- G/Q?
if neobundle#tap('vim-textobj-space')  "{{{
  let g:textobj_space_no_default_key_mappings = 1
  xmap <silent><unique> as <Plug>(textobj-space-a)
  omap <silent><unique> as <Plug>(textobj-space-a)
  xmap <silent><unique> is <Plug>(textobj-space-i)
  omap <silent><unique> is <Plug>(textobj-space-i)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-sigil')  "{{{
  let g:textobj_sigil_no_default_key_mappings = 1
  xmap <silent><unique> ag <Plug>(textobj-sigil-a)
  omap <silent><unique> ag <Plug>(textobj-sigil-a)
  xmap <silent><unique> ig <Plug>(textobj-sigil-i)
  omap <silent><unique> ig <Plug>(textobj-sigil-i)
  call neobundle#untap()
endif "}}}


"{{{1 Specific ============================
if neobundle#tap('sideways.vim')  "{{{
  xmap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
  omap <silent><unique> aa <Plug>SidewaysArgumentTextobjA

  xmap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
  omap <silent><unique> ia <Plug>SidewaysArgumentTextobjI

  noremap <silent><unique> [a :<C-u>SidewaysJumpLeft<CR>
  noremap <silent><unique> ]a :<C-u>SidewaysJumpRight<CR>

  " NOTE: overrides 'ga -- print ascii for letter', do 'unmap ga' on demand
  nnoremap <silent><unique> ga :SidewaysLeft<CR>
  nnoremap <silent><unique> gA :SidewaysRight<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-signify')  "{{{
  let g:signify_vcs_list = [ 'git', 'hg', 'cvs' ]
  let g:signify_sign_change = '~'
  let g:signify_sign_delete = '-'

  noremap <unique> <leader>tg :<C-u>SignifyToggle \| redraw!<CR>
  noremap <unique> <leader>tG :<C-u>SignifyToggleHighlight \| redraw!<CR>
  "" Already mapped -- if busy: automaps <leader>gj and <leader>gk
  " nmap <unique> ]c <Plug>(signify-next-hunk)
  " nmap <unique> [c <Plug>(signify-prev-hunk)

  xmap <silent><unique> aS <Plug>(signify-motion-outer-visual)
  omap <silent><unique> aS <Plug>(signify-motion-outer-pending)
  xmap <silent><unique> iS <Plug>(signify-motion-inner-visual)
  omap <silent><unique> iS <Plug>(signify-motion-inner-pending)
  call neobundle#untap()
endif "}}}
