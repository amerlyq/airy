"{{{1 Actions ============================
if neobundle#tap('vim-expand-region') "{{{
  xmap <silent><unique> + <Plug>(expand_region_expand)
  xmap <silent><unique> - <Plug>(expand_region_shrink)
  call neobundle#untap()
endif "}}}
