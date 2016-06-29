""" Windows

"" (DISABLED) Sublime-like minimap {{{1
" BAD:(performance,artifacts)
" call dein#add('severin-lemaignan/vim-minimap', {'on_cmd': 'MinimapToggle'})



"" Nice automatic view/scale/ctrl for split windows {{{1
" SEE http://zhaocai.github.io/GoldenView.Vim
" NOT:(lazy) because I split by many different ways from the start
call dein#add('zhaocai/GoldenView.Vim', {'lazy': 0,
  \ 'on_map': ['<Plug>GoldenView', '<Plug>ToggleGoldenView'],
  \ 'hook_source': "
\\n   let g:goldenview__enable_at_startup = 1
\\n   let g:goldenview__enable_default_mapping = 0
\"})
" \ 'hook_post_source': "
" \\n   call GoldenView#ExtendProfile('small-height', {'other_window_winheight': 2})
" \\n   let g:goldenview__active_profile = 'small-height'
" \"})

if dein#tap('GoldenView.Vim')
  " ALSO :Disable*, :Enable*
  noremap <unique>      [Toggle]m  <Plug>ToggleGoldenViewAutoResize
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
endif
