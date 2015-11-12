" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
" NOTE: more prefixes: use <Leader>T[key] and <Leader>t<leader>[key]

" Often I need to disable it completely when investigating other's sources
" DEV TODO ',tL' -- toggle list chars more visible -- by high-contrast solarized
nnoremap <unique> <Leader>tl :set list! list?<CR>
nnoremap <unique> <Leader>tN :NeoCompleteToggle<CR>

" Local buffer
nnoremap <unique> <Leader>th :setl hlsearch! hls?<CR>
nnoremap <unique> <Leader>ts :setl spell! spelllang=en_us,ru_yo,uk spell?<CR>
nnoremap <unique> <Leader>tc :setl cursorcolumn! cuc?<CR>
nnoremap <unique> <Leader>tC :setl cursorline! cul?<CR>

" Toggle status line only
nnoremap <unique> <Leader>tA :let &laststatus=(&ls?0:2) \| :AirlineToggle<CR>
" Toggle all UI elements NEED DEV save/restore current state instead hardcode!
""showcmd! ruler!
nnoremap <unique> <Leader>tf :set number! showmode!
      \\| let &foldcolumn=(&fdc?0:2) \| let &laststatus=(&ls?0:2)
      \\| SignifyToggle \| AirlineToggle \| SignatureToggleSigns<CR><CR>

" Toggle between number and relativenumber
set number
nnoremap <unique> <Leader>tn :set relativenumber! \| set rnu?<CR>


noremap <unique> <Leader>tx :<C-u>SyntasticToggleMode<CR>
"\| :SyntasticCheck<CR>

" Syntax highlighting
syntax enable
nnoremap <unique> <Leader>tX :exe 'syn' (exists("g:syntax_on")?'off': 'enable')<CR>
