if has('gui')
  " Use CSApprox.vim
  NeoBundleSource csapprox

  " Convert colorscheme in Konsole.
  let g:CSApprox_konsole = 1
  let g:CSApprox_attr_map = {
        \ 'bold' : 'bold',
        \ 'italic' : '', 'sp' : ''
        \ }
  if !exists('g:colors_name')
    execute 'colorscheme' globpath(&runtimepath,
          \ 'colors/candy.vim') != '' ? 'candy' : 'desert'
  endif
elseif has('nvim') && $NVIM_TUI_ENABLE_TRUE_COLOR != ''
  " Use true color feature
  colorscheme candy
else
  " Use guicolorscheme.vim
  NeoBundleSource vim-guicolorscheme

  autocmd MyAutoCmd VimEnter,BufAdd *
        \ if !exists('g:colors_name') | GuiColorScheme candy

  " Disable error messages.
  let g:CSApprox_verbose_level = 0
endif

if IsWindows()
  " Change colorscheme.
  " Don't override colorscheme.
  if !exists('g:colors_name') && !has('gui_running')
    colorscheme darkblue
  endif
  " Disable error messages.
  let g:CSApprox_verbose_level = 0

  " Popup color.
  hi Pmenu ctermbg=8
  hi PmenuSel ctermbg=1
  hi PmenuSbar ctermbg=0
endif
