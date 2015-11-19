"{{{1 Operators ============================
if neobundle#tap('vim-operator-surround')  "{{{
  for op in ['append', 'delete', 'replace']
    call Map_nxo('[Quote]'.op[0], '<Plug>(operator-surround-'.op.')', 'nx')
  endfor
  call neobundle#untap()

  if neobundle#tap('vim-textobj-between')  "{{
    " Surrounding symbols for current cursor position (like 'f`')
    nmap <silent><unique> [Quote]f <Plug>(operator-surround-replace)<Plug>(textobj-between-a)
    nmap <silent><unique> [Quote]F <Plug>(operator-surround-delete)<Plug>(textobj-between-a)
    call neobundle#untap()
  endif

  if neobundle#tap('vim-textobj-quotes')  "{{{
    " Quoted (outer) expr is the most useful:
    omap <silent><unique> q aq
    call neobundle#untap()
  endif "}}}

  if neobundle#tap('vim-textobj-anyblock')  "{{{
    " CHECK: let b:textobj_anyblock_buffer_local_blocks = [ ':', '*' ]
    " Current enclosing block of ({["'<`
    nmap <silent><unique> [Quote]b <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
    nmap <silent><unique> [Quote]B <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
    " Explicit shortcuts
    nmap <silent><unique> [Quote]Q <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)"<Esc>

    " TODO:THINK:RFC: use getchar() instead of direct mappings?
    "   = Redirect if no such mappings exists (see inside op-surr src)
    let s:op = '<Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)'
    for cg in ['()0', '{}9', '[]8', '"2', "'1", '<>3.', '`4']
      for c in split(cg, '\zs')
        " for k in ['', '[Space]', 'g[Space]', '<Leader>[Space]']
          call Map_nxo('[Quote]'.c, s:op . cg[0], 'nx')
        " endfor
      endfor
    endfor
    call neobundle#untap()
  endif "}}}
endif "}}}


if neobundle#tap('vim-operator-replace') "{{{
  " THINK Could be used instead of my own paste-replace?
  " xmap p <Plug>(operator-replace)
  map <silent><unique> gr <Plug>(operator-replace)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-exchange') "{{{
  xmap <silent><unique> X   <Plug>(Exchange)
  nmap <silent><unique> cx  <Plug>(Exchange)
  nmap <silent><unique> cxc <Plug>(ExchangeLine)
  nmap <silent><unique> cxx <Plug>(ExchangeClear)
  call neobundle#untap()
endif "}}}


if neobundle#tap('sideways.vim')  "{{{
  xmap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
  omap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
  xmap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
  omap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
  " NOTE: overrides 'ga -- print ascii for letter', do 'norm! ga' on demand
  nmap <silent><unique> ga <Plug>SidewaysLeft
  nmap <silent><unique> gA <Plug>SidewaysRight
  " TODO replace with ',a' OR '<Tab>a', and move Ag to '[Frame]a]'
  noremap <silent><unique> [a :<C-u>SidewaysJumpLeft<CR>
  noremap <silent><unique> ]a :<C-u>SidewaysJumpRight<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-clang-format')  "{{{ H100%, S45%
  " SEE: http://clang.llvm.org/docs/ClangFormatStyleOptions.html
  " let g:clang_format#auto_format = 1
  " let g:clang_format#auto_format_on_insert_leave = 1
  let g:clang_format#code_style='google'  " llvm, google, chromium, mozilla
  let g:clang_format#auto_formatexpr = 1
  " OR au MyAutoCmd FileType c,cpp,objc
  "       \ map <buffer> gq <Plug>(operator-clang-format)
  au MyAutoCmd FileType c,cpp,objc
          \ nnoremap <buffer> gQ :<C-u>ClangFormat<CR>
  "" For config information, exec: $ clang-format -dump-config
  let g:clang_format#style_options = {
      \ "AccessModifierOffset" : -4,
      \ "AllowShortIfStatementsOnASingleLine" : "true",
      \ "AlwaysBreakTemplateDeclarations" : "true",
      \ "Standard" : "C++11",
      \ }
      " \ "BreakBeforeBraces" : "Stroustrup",
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-autoformat')  "{{{
  noremap <F6> :Autoformat<CR><CR>
  call neobundle#untap()
endif "}}}


"{{{1 Textobj ============================
if neobundle#tap('vim-textobj-entire')  "{{{
  let g:textobj_entire_no_default_key_mappings = 1
  xmap <silent><unique> aG <Plug>(textobj-entire-a)
  omap <silent><unique> aG <Plug>(textobj-entire-a)
  xmap <silent><unique> iG <Plug>(textobj-entire-i)
  omap <silent><unique> iG <Plug>(textobj-entire-i)
  call neobundle#untap()
endif "}}}

"{{{1 Textobj ============================
if neobundle#tap('vim-textobj-function')  "{{{
  let g:textobj_function_no_default_key_mappings = 1
  xmap <silent><unique> aF  <Plug>(textobj-function-a)
  omap <silent><unique> aF  <Plug>(textobj-function-a)
  xmap <silent><unique> iF  <Plug>(textobj-function-i)
  omap <silent><unique> iF  <Plug>(textobj-function-i)
  xmap <silent><unique> agf <Plug>(textobj-function-A)
  omap <silent><unique> agf <Plug>(textobj-function-A)
  xmap <silent><unique> igf <Plug>(textobj-function-I)
  omap <silent><unique> igf <Plug>(textobj-function-I)
  call neobundle#untap()
endif "}}}

if neobundle#tap('vim-textobj-sigil')  "{{{
  let g:textobj_sigil_no_default_key_mappings = 1
  xmap <silent><unique> ad <Plug>(textobj-sigil-a)
  omap <silent><unique> ad <Plug>(textobj-sigil-a)
  xmap <silent><unique> id <Plug>(textobj-sigil-i)
  omap <silent><unique> id <Plug>(textobj-sigil-i)
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


if neobundle#tap('vim-textobj-syntax')  "{{{
  let g:textobj_syntax_no_default_key_mappings = 1
  " ATTENTION currently textobj-syntax-a acts the same as textobj-syntax-i
  xmap <silent><unique> ah <Plug>(textobj-syntax-a)
  omap <silent><unique> ah <Plug>(textobj-syntax-a)
  xmap <silent><unique> ih <Plug>(textobj-syntax-i)
  omap <silent><unique> ih <Plug>(textobj-syntax-i)
  call neobundle#untap()
endif "}}}


"{{{1 Motions ============================
if neobundle#tap('matchit.zip') "{{{
  fun! neobundle#hooks.on_post_source(bundle)
    silent! exe 'doautocmd Filetype' &filetype
  endf
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


if neobundle#tap('vim-signify')  "{{{
  let g:signify_vcs_list = [ 'git', 'hg', 'cvs' ]
  let g:signify_sign_change = '~'
  let g:signify_sign_delete = '-'
  noremap <unique> [Frame]gg :<C-u>SignifyFold<CR>
  " FIND:THINK: isn't :SignifyRefresh unnecessary?
  noremap <unique> <leader>tg :<C-u>SignifyToggle \| SignifyRefresh<CR>
  noremap <unique> <leader>tG :<C-u>SignifyToggleHighlight \| SignifyRefresh<CR>
  "" Already mapped -- if busy: automaps <leader>gj and <leader>gk
  nmap <silent><unique> ]c <Plug>(signify-next-hunk)
  nmap <silent><unique> [c <Plug>(signify-prev-hunk)
  " Textobj -- changed areas
  xmap <silent><unique> aS <Plug>(signify-motion-outer-visual)
  omap <silent><unique> aS <Plug>(signify-motion-outer-pending)
  xmap <silent><unique> iS <Plug>(signify-motion-inner-visual)
  omap <silent><unique> iS <Plug>(signify-motion-inner-pending)
  call neobundle#untap()
endif "}}}


"{{{1 Actions ============================
if neobundle#tap('vim-expand-region') "{{{
  xmap <silent><unique> + <Plug>(expand_region_expand)
  xmap <silent><unique> - <Plug>(expand_region_shrink)
  call neobundle#untap()
endif "}}}
