
" call deoplete#custom#source('ultisnips', 'rank', 1000)
" call deoplete#custom#set('ultisnips', 'matchers', ['matcher_fuzzy'])

"" ALT: UltiSnips#CanExpandSnippet() | UltiSnips#CanJumpForwards()
" function UltiSnips_IsExpandable()
"   return !(
"     \ col('.') <= 1
"     \ || !empty(matchstr(getline('.'), '\%' . (col('.') - 1) . 'c\s'))
"     \ || empty(UltiSnips#SnippetsInCurrentScope())
"     \ )
" endfunction

" UltiSnips_IsExpandable()
" inoremap <expr> <CR> pumvisible() ? UltiSnips#ExpandSnippetOrJump() : "\<CR>"
" inoremap <silent> <F12> <C-R>=(pumvisible()? "\<LT>C-E>":"")<CR><C-R>=UltiSnipsCallUnite()<CR>
" nnoremap <silent> <F12> a<C-R>=(pumvisible()? "\<LT>C-E>":"")<CR><C-R>=UltiSnipsCallUnite()<CR>

" let g:ulti_expand_or_jump_res = 0
" function! Ulti_ExpandOrJump_and_getRes()
"   call UltiSnips#ExpandSnippetOrJump()
"   return g:ulti_expand_or_jump_res
" endfunction
" inoremap <NL> <C-R>=(Ulti_ExpandOrJump_and_getRes() > 0)?"":IMAP_Jumpfunc('', 0)<CR>
" inoremap <silent> <C-j> <C-R>=(Ulti_ExpandOrJump_and_getRes() > 0) ? "" : ""<CR>
" inoremap <silent> <C-j> <C-R>=UltiSnips#ExpandSnippetOrJump()<CR>
