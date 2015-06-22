" vim:ts=2:sw=2:sts=2
" NOTE: more prefixes: use <Leader>T[key] and <Leader>t<leader>[key]

" Toggle status line
nnoremap <unique> <Leader>ta :set laststatus=<C-R>=&laststatus?0 :2<CR> \| :AirlineToggle<CR>

" Often I need to disable it completely when investigating other's sources
nnoremap <unique> <Leader>tl :set list! list?<CR>
nnoremap <unique> <Leader>tL :NeoCompleteToggle<CR>

nnoremap <unique> <Leader>th :setlocal hlsearch! hlsearch?<CR>
nnoremap <unique> <Leader>ts :setlocal spell! spelllang=en_us,ru_yo,uk spell?<CR>
nnoremap <unique> <Leader>tc :setlocal cursorcolumn! cursorcolumn?<CR>
nnoremap <unique> <Leader>tC :setlocal cursorline! cursorline?<CR>
nnoremap <unique> <Leader>tW :setlocal wrap! breakindent!<CR>

" magnifying when switching (more stable then 'hjkl<C-W>_' )
let g:magnify_on = 1
noremap <unique> <Leader>tw :<C-U>let g:magnify_on = g:magnify_on ? 0 : 1 \|
      \ echo('  wmagnify = ' . (g:magnify_on ? 'on' : 'off'))<CR>
autocmd WinEnter * call AutoMagnifying()
function! AutoMagnifying()
  if g:magnify_on
    resize 100    "or another big number
  endif
endfunc

" Слева появится колонка шириной в 3 символа, обозначающая где какие фолдинги
" и какого уровня.  По ней можно будет кликать для сворачивания-разворачивания.
set foldenable foldcolumn=2
nnoremap <unique> <Leader>tz :call ToggleFoldingMethod() \| set fdm?<CR>
nnoremap <unique> <Leader>tZ :call ToggleFolding() \| set fen?<CR>

function! ToggleFoldingMethod()
    if(&foldmethod == "manual")
        set foldmethod=syntax
    elseif(&foldmethod == "syntax")
        set foldmethod=marker
    else
        set foldmethod=manual
    endif
endfunc
function! ToggleFolding()
    if(&foldenable == 1)
        set nofoldenable
        set foldcolumn=0
    else
        set foldenable
        set foldcolumn=2
    endif
endfunc


" toggle between number and relativenumber
set number
nnoremap <unique> <Leader>tN :setlocal number! number?<CR>
nnoremap <unique> <Leader>tn :call ToggleNumber() \| set rnu?<CR>
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc


noremap <unique> <Leader>tx <Esc>:SyntasticToggleMode<CR>
"\| :SyntasticCheck<CR>
" Syntax highlighting
syntax on
nnoremap <unique> <Leader>tX :call ToggleSyntax()<CR>
function! ToggleSyntax()
if g:syntax_on == 1
  syntax off
  let g:syntax_on = 0
else
  syntax on
  let g:syntax_on = 1
endif
endfunction


