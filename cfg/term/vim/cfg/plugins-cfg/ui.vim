"{{{1 Windows ============================
if neobundle#tap('GoldenView.Vim') "{{{
  let g:goldenview__enable_at_startup = 1
  let g:goldenview__enable_default_mapping = 0
  " ALSO :Disable*, :Enable*
  noremap <unique>      [Toggle]m <Plug>ToggleGoldenViewAutoResize
  " Do automatic/manual resizing of focused window, or split it
  nmap <unique><silent> [Frame]wt  <Plug>ToggleGoldenViewAutoResize
  nmap <unique><silent> [Frame]ws  <Plug>GoldenViewSplit
  nmap <unique><silent> [Frame]wr  <Plug>GoldenViewResize
  " Jump to next/prev or choosen
  nmap <unique><silent> [Frame]wn  <Plug>GoldenViewNext
  nmap <unique><silent> [Frame]wp  <Plug>GoldenViewPrevious
  " Switch current window with one of others and toggle back
  nmap <unique><silent> [Frame]ww  <Plug>GoldenViewSwitchToggle
  nmap <unique><silent> [Frame]wm  <Plug>GoldenViewSwitchMain
  nmap <unique><silent> [Frame]wl  <Plug>GoldenViewSwitchWithLargest
  nmap <unique><silent> [Frame]wk  <Plug>GoldenViewSwitchWithSmallest
  " Make windows equal (useful for vsplits on 1/4 of screen)
  nmap <unique><silent> [Frame]w=  <Plug>GoldenViewResize<C-w>=
  " fun! neobundle#hooks.on_source(bundle)
  "   call GoldenView#ExtendProfile('small-height',
  "       \ { 'other_window_winheight': 2 })
  "   let g:goldenview__active_profile = 'small-height'
  " endfun
  call neobundle#untap()
endif "}}}


"{{{1 Indicators ============================
if neobundle#tap('vim-signify')  "{{{
  let g:signify_vcs_list = [ 'git', 'hg', 'cvs' ]
  let g:signify_sign_change = '~'
  let g:signify_sign_delete = '-'
  noremap <unique> [Frame]gg :<C-u>SignifyFold<CR>
  " FIND:THINK: isn't :SignifyRefresh unnecessary?
  noremap <unique> [Toggle]g :<C-u>SignifyToggleHighlight \| SignifyRefresh<CR>
  noremap <unique> [Toggle]G :<C-u>SignifyToggle<CR>
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


if neobundle#tap('vim-signature')  "{{{
  let g:SignatureIncludeMarkers = '!@#$%^&*()'  " CHECK: >= 10, USE? \"
  let g:SignaturePurgeConfirmation = 1
  let g:SignaturePrioritizeMarks = 0
  let g:SignatureMap = { 'PurgeMarks': "m<Del>" }
  fun! neobundle#hooks.on_post_source(bundle)
    silent! exe 'doautocmd sig_autocmds BufEnter'
  endf
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-quickhl')  "{{{
   map <unique> [Quote]h  <Plug>(operator-quickhl-manual-this-motion)
  nmap <unique> [Quote]H  <Plug>(quickhl-manual-reset)
  nmap <unique> <Leader>?h  :QuickhlManualList<CR>
  nmap <unique> [Toggle]h  <Plug>(quickhl-cword-toggle)
  nmap <unique> <Leader>Th  <Plug>(quickhl-manual-toggle)
  "" ATTENTION: unusable on big tag base (like kernels)
  nmap <unique> <Leader>TH  <Plug>(quickhl-tag-toggle)
  " let g:quickhl_manual_colors = [ "ctermbg=..", ... ]
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-indent-guides')  "{{{
  nnoremap <unique> [Toggle]I :IndentGuidesToggle<CR>
  let g:indent_guides_enable_on_vim_startup = 1
  let g:indent_guides_exclude_filetypes = [
        \ 'votl', 'iav_term']  " SEE RangerChooser
  " Make 1-wide guide, don't works on Hard-Tabs
  let g:indent_guides_guide_size = 1
  let g:indent_guides_start_level = 2
  let g:indent_guides_indent_levels = 20
  let g:indent_guides_tab_guides = 0
  " At the moment Terminal Vim only has basic support.
  " So colors won't be autocalculated from your colorscheme.
  let g:indent_guides_auto_colors = 0
  let g:indent_guides_color_change_percent = 10
  let g:indent_guides_default_mapping = 0
  call neobundle#untap()
endif "}}}


if neobundle#tap('rainbow')  "{{{
  let g:rainbow_active = 1
  let g:rainbow_conf = {'separately': {'*': 0}}
  let g:rainbow_conf.ctermfgs = [160, 202, 178, 34, 33, 129]  " BEST: lisp, vim
  " Activates only specified languages
  let g:rainbow_conf.separately.c = {'ctermfgs': [7, 7] + g:rainbow_conf.ctermfgs}
  let g:rainbow_conf.separately.lisp = {}
  let g:rainbow_conf.separately.vim = {}
  " 'sh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
  " 'zsh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
  call neobundle#untap()
endif "}}}


"{{{1 Status/Colors ============================
if neobundle#tap('vim-airline')  "{{{
  let g:airline#extensions#tabline#buffer_idx_mode = 1
  for i in range(1,9)  " Directly pick buffer on [Frame]\d
    call Map_nxo('[Frame]'.i, '<Plug>AirlineSelectTab'.i, 'n')
  endfor
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/airline.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-colors-solarized')  "{{{
  " nmap <unique> <F12> <Plug>ToggleBackground
  " xmap <unique> <F12> <Plug>ToggleBackground
  " imap <unique> <F12> <Plug>ToggleBackground
  let g:solarized_menu=0
  if has('gui_running') || $TERM =~# '^rxvt'  "\|nvim
    let g:solarized_termcolors=16  " Use only with pre-setup palette!
  elseif &t_Co > 16  " If ~256 -- makes brown bg and bold font...
    let g:solarized_termcolors=&t_Co  " Choose similar colors from palette
    let g:airline_theme = 'badwolf'  " seren
  else | echom "Too much reduced palette for solarized colorscheme" | endif
  " let g:solarized_contrast="high"    "high|normal|low  -- stich with normal!
  let g:solarized_visibility="low"    "high|normal|low -- for tab/nl/space
  let g:solarized_hitrail=0
  " g:solarized_termtrans = 0
  let g:solarized_bold=1
  let g:solarized_underline=1
  let g:solarized_italic=1
  call neobundle#untap()
endif "}}}
