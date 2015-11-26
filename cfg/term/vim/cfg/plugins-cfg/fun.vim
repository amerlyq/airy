if neobundle#tap('CCTree') "{{{
  " Launch with default DB
  command! -bar  CCTree  CCTreeLoadDB cscope.out

  fun! neobundle#hooks.on_source(bundle)
    " Settings
    " let g:CCTreeUsePerl = 1  " TRY? Faster? Robust?
    let g:CCTreeCscopeDb = 'cscope.out'
    " let g:CCTreeRecursiveDepth = 3
    let g:CCTreeMinVisibleDepth = 0
    " let g:CCTreeWindowVertical = 1
    let g:CCTreeDisplayMode = 1  "1-3, 3 good for hor split
    let g:CCTreeUseUTF8Symbols = 1
    " let g:CCTreeHilightCallTree = 0

    " Key-mappings
    " Open symbol in other window       <CR>
    " Preview symbol in other window    <Ctrl-P>
    let g:CCTreeKeyTraceForwardTree = '<LocalLeader>f'  " >
    let g:CCTreeKeyTraceReverseTree = '<LocalLeader>r'  " <
    let g:CCTreeKeyDepthPlus = '<LocalLeader>m'   " =
    let g:CCTreeKeyDepthMinus = '<LocalLeader>l'  " -
    let g:CCTreeKeySaveWindow = '<LocalLeader>y'
    let g:CCTreeKeyToggleWindow = '<LocalLeader>w'
    let g:CCTreeKeyCompressTree = 'zs'      " Compress call-tree
    " BUG: dont? -- Static HL for current flow
    let g:CCTreeKeyHilightTree = '<LocalLeader>h'

    " au PatchColorScheme ColorScheme *
    hi! CCTreeMarkers   ctermfg=11 ctermbg=NONE
    hi! CCTreeHiMarkers ctermfg=7  ctermbg=NONE
    " hi! link CCTreeHiSymbol  Statement
  endf

  fun! neobundle#hooks.on_post_source(bundle)
    CCTree  " Load DB by using lazy mappings
  endf

  call neobundle#untap()
endif "}}}
