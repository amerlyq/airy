if neobundle#tap('vim-submode') "{{{
  "" WARNING:HACK: limitations: len({lhs})~10, can't use <SID> -- NEED comm!
  "" FIXME: [count] not supported. USE 'r' to use 'map' instead of 'noremap'
  "" NOTE leaves on any not defined key, impossible to disable all other maps

  "" DEV:USE: airline-ext for this -- hide/show directly after real mode on left
  "" DISABLED: redraw! on mode-leave in terminal results in flickering
  let g:submode_always_show_submode = 0
  let g:submode_timeout = 0
  let g:submode_timeoutlen = 0
  "" USE if you want action on mode leave instead of silent consume
  let g:submode_keep_leaving_key = 1
  " let g:submode_keyseqs_to_leave = ['<Esc>']

  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/submodes-define.vim'
  call neobundle#untap()
endif "}}}
