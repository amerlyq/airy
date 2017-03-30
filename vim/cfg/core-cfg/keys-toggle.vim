" Syntax highlighting
nnoremap <unique> [Toggle]S :exe 'syn' exists("g:syntax_on")?'off':'enable'<CR>
nnoremap <unique> [Toggle]M :let &mouse=(''==&mouse?'a':'')\|set mouse?<CR>

if has('conceal')
  noremap <silent><unique> [Toggle]y
    \ :<C-u>call <SID>tgl_cocu(v:count)\|set concealcursor?<CR>
  let s:cocu = ('' != &cocu ? &cocu : 'nv')
  fun! s:tgl_cocu(c)
    let d = ['', 'n', 'v', 'i', 'c']
    let v = join(map(split(string(a:c), '\zs'), 'get(l:d,v:val,"")'), '')
    if '' != l:v| let s:cocu = l:v |en
    let &cocu = (('' != l:v || '' == &cocu) ? s:cocu : '')
  endf

  noremap <silent><unique> [Toggle]Y
    \ :<C-u>call <SID>tgl_cole(v:count)\|set conceallevel?<CR>
  let s:cole = (&cole ? &cole : 2)
  fun! s:tgl_cole(c)
    if a:c| let s:cole = a:c |en
    let &cole = ((a:c || !&cole) ? s:cole : 0)
  endf
endif

" Toggle all UI elements NEED DEV save/restore current state instead hardcode!
" DEV check if command exists before! Save previous DFL values for ':set'
""showcmd! showmode! ruler!
nnoremap <silent><unique> [Toggle]f :set number!
      \\| let &foldcolumn=(&fdc?0:2) \| let &laststatus=(&ls?0:2)
      \\| SignifyToggle \| RelnumToggle \| AirlineToggle
      \\| SignatureToggleSigns<CR>
