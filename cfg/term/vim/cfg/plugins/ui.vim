""" Windows

"" (DISABLED) Sublime-like minimap {{{1
" BAD:(performance,artifacts)
" call dein#add('severin-lemaignan/vim-minimap', {'on_cmd': 'MinimapToggle'})


"" Tmux-like jump to window by index
" ALT: [Frame]\\
" THINK: remove all my 'z[lLhH]' mappings
call dein#add('t9md/vim-choosewin', {
  \ 'on_map': [['n', '<Plug>(choosewin)']],
  \ 'hook_source': "
\\n   let g:choosewin_overlay_enable = 1
\\n   let g:choosewin_overlay_clear_multibyte = 1
\\n   let g:choosewin_blink_on_land = 0
\", 'hook_add': "
\\n   nmap <silent><unique>  <C-j>  <Plug>(choosewin)
\"})


"" Nice automatic view/scale/ctrl for split windows {{{1
" SEE http://zhaocai.github.io/GoldenView.Vim
" NOT:(lazy) because I split by many different ways from the start
call dein#add('zhaocai/GoldenView.Vim', {'lazy': 0,
  \ 'on_map': [['n', '<Plug>GoldenView', '<Plug>ToggleGoldenView']],
  \ 'hook_add': _hcat('golden-view.add'),
  \ 'hook_source': "
\\n   let g:goldenview__enable_at_startup = 1
\\n   let g:goldenview__enable_default_mapping = 0
\"})
" \ 'hook_post_source': "
" \\n   call GoldenView#ExtendProfile('small-height', {'other_window_winheight': 2})
" \\n   let g:goldenview__active_profile = 'small-height'
" \"})
