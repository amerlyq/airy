" Syntax highlighting
nnoremap <unique> [Toggle]S :exe 'syn' exists("g:syntax_on")?'off':'enable'<CR>
nnoremap <unique> [Toggle]M :let &mouse=(''==&mouse?'a':'')\|set mouse?<CR>

if has('conceal')
  let s:cole = &conceallevel
  fun! s:tgl_cole(c)
    if a:c| let s:cole = a:c |en
    let &cole = (a:c || 0 == &cole) ? s:cole : 0
  endfun
  " BUG: jumps 1/2 lines down when using v:count=2/3
  nnoremap <silent><unique> [Toggle]y :call <SID>tgl_cole(v:count)\|set cole?<CR>
endif

" Toggle all UI elements NEED DEV save/restore current state instead hardcode!
" DEV check if command exists before! Save previous DFL values for ':set'
""showcmd! showmode! ruler!
nnoremap <silent><unique> [Toggle]f :set number!
      \\| let &foldcolumn=(&fdc?0:2) \| let &laststatus=(&ls?0:2)
      \\| SignifyToggle \| RelnumToggle \| AirlineToggle
      \\| SignatureToggleSigns<CR>
