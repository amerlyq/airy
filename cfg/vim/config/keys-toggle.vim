" vim:ts=2:sw=2:sts=2
" NOTE: more prefixes: use <Leader>T[key] and <Leader>t<leader>[key]

" Toggle status line
nnoremap <Leader>ta :set laststatus=<C-R>=&laststatus?0 :2<CR> \| :AirlineToggle<CR>

" Often I need to disable it completely when investigating other's sources
nnoremap <Leader>tl :set list! list?<CR>

nnoremap <Leader>th :setlocal hlsearch! hlsearch?<CR>
nnoremap <Leader>tp :setlocal spell! spell?<CR>
nnoremap <Leader>tc :setlocal cursorcolumn! cursorcolumn?<CR>
nnoremap <Leader>tC :setlocal cursorline! cursorline?<CR>

" magnifying when switching (more stable then 'hjkl<C-W>_' )
let g:magnify_on = 1
noremap <Leader>tw :<C-U>let g:magnify_on = g:magnify_on ? 0 : 1 \|
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
nnoremap <Leader>tz :call ToggleFoldingMethod() \| set fdm?<CR>
nnoremap <Leader>tZ :call ToggleFolding() \| set fen?<CR>

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
nnoremap <Leader>tN :setlocal number! number?<CR>
nnoremap <Leader>tn :call ToggleNumber() \| set rnu?<CR>
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" Syntax highlighting
syntax on
nnoremap <Leader>ts :call ToggleSyntax()<CR>
function! ToggleSyntax()
if g:syntax_on == 1
  syntax off
  let g:syntax_on = 0
else
  syntax on
  let g:syntax_on = 1
endif
endfunction

noremap <Leader>tx <Esc>:SyntasticToggleMode<CR>
"\| :SyntasticCheck<CR>

