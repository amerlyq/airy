fun! s:Map_block(prefix, mapping, mode)
  let l:bchars = ['()0', '{}9', '[]8', '"2', "'1", '<>3.', '`4']
  for cg in l:bchars | for c in split(cg, '\zs')
    " for k in ['', '[Space]', 'g[Space]', '<Leader>[Space]']
    call Map_nxo(a:prefix.c, a:mapping.cg[0], a:mode)
  endfor | endfor
endf


"{{{1 Operators ============================
if neobundle#tap('vim-operator-surround')  "{{{
  for op in ['append', 'delete', 'replace']
    call Map_nxo('[Quote]'.op[0], '<Plug>(operator-surround-'.op.')', 'nx')
  endfor
  call s:Map_block('[Quote]', '<Plug>(operator-surround-append)', 'x')
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
    " TODO:THINK:RFC: use getchar() instead of direct mappings?
    "   = Redirect if no such mappings exists (see inside op-surr src)
    let s:op = '<Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)'
    call s:Map_block('[Quote]', s:op, 'n')
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
