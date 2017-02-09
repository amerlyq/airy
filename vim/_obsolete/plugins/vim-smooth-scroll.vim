if neobundle#tap('vim-smooth-scroll') "{{{
  noremap <silent><unique> <C-u> :<C-u>call smooth_scroll#up(&scroll, 0, 2)<CR>
  noremap <silent><unique> <C-d> :<C-u>call smooth_scroll#down(&scroll, 0, 2)<CR>
  noremap <silent><unique> <C-b> :<C-u>call smooth_scroll#up(&scroll*2, 0, 4)<CR>
  noremap <silent><unique> <C-f> :<C-u>call smooth_scroll#down(&scroll*2, 0, 4)<CR>
  call neobundle#untap()
endif "}}}
