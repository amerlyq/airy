" Syntax highlighting
nnoremap <unique> [Toggle]S :exe 'syn' exists("g:syntax_on")?'off':'enable'<CR>
nnoremap <unique> [Toggle]s :setl spell! spelllang=en_us,ru_yo,uk spell?<CR>
nnoremap <unique> [Toggle]M :let &mouse=(''==&mouse?'a':'')\|set mouse?<CR>

" Toggle all UI elements NEED DEV save/restore current state instead hardcode!
" DEV check if command exists before! Save previous DFL values for ':set'
""showcmd! showmode! ruler!
nnoremap <silent><unique> [Toggle]f :set number!
      \\| let &foldcolumn=(&fdc?0:2) \| let &laststatus=(&ls?0:2)
      \\| SignifyToggle \| RelnumToggle \| AirlineToggle
      \\| SignatureToggleSigns<CR>
