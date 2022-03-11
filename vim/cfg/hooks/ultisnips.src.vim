" HACK: same as ",s" -- to return to NORMAL after all placeholders filled
inoremap <silent>  <C-j>  <Esc>:update<CR>

let g:UltiSnipsExpandTrigger = '<C-j>'
let g:UltiSnipsListSnippets = '<C-s>'

" call deoplete#custom#source('ultisnips', 'rank', 1000)

"" TEMP:FIXED:MOVE=deoplete.src.vim
"" HACK: also show one-letter snippets, and show snippets on top of others
" SRC: https://github.com/Shougo/deoplete.nvim/issues/404
" OR: 'matcher_head'
" call deoplete#custom#source('ultisnips',
"   \ {'matchers': ['matcher_fuzzy'], 'rank': 1000})

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


function! UltiSnipsCallUnite()
  Unite -start-insert -winheight=100 -immediately -no-empty ultisnips
  return ''
endfunction
inoremap <silent> <F4> <C-R>=(pumvisible()? "\<LT>C-E>":"")<CR><C-R>=UltiSnipsCallUnite()<CR>
nnoremap <silent> <F4> a<C-R>=(pumvisible()? "\<LT>C-E>":"")<CR><C-R>=UltiSnipsCallUnite()<CR>

" let g:ulti_expand_or_jump_res = 0
" function! Ulti_ExpandOrJump_and_getRes()
"   call UltiSnips#ExpandSnippetOrJump()
"   return g:ulti_expand_or_jump_res
" endfunction
" inoremap <NL> <C-R>=(Ulti_ExpandOrJump_and_getRes() > 0)?"":IMAP_Jumpfunc('', 0)<CR>
" inoremap <silent> <C-j> <C-R>=(Ulti_ExpandOrJump_and_getRes() > 0) ? "" : ""<CR>
" inoremap <silent> <C-j> <C-R>=UltiSnips#ExpandSnippetOrJump()<CR>
