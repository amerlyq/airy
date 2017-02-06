""" GoldenView.Vim

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
