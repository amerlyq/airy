if neobundle#tap('deoplete.nvim') && has('nvim') "{{{
  let g:deoplete#enable_at_startup = 1

  fun! neobundle#hooks.on_source(bundle)
    set completeopt+=noinsert
    function! s:check_back_space() "{{{
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~ '\s'
    endfunction"}}}
    " <TAB>: completion.
    imap <silent><expr> <TAB>
          \ pumvisible() ? "\<C-n>" :
          \ <SID>check_back_space() ? "\<TAB>" :
          \ deoplete#mappings#manual_complete()
    " <S-TAB>: completion back.
    inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<C-h>"
    " <C-h>, <BS>: close popup and delete backword char.
    inoremap <expr><C-h> deolete#mappings#smart_close_popup()."\<C-h>"
    inoremap <expr><BS> deoplete#mappings#smart_close_popup()."\<C-h>"
    inoremap <expr> '  pumvisible() ? deoplete#mappings#close_popup() : "'"
    " Use head matcher
    " call deoplete#custom#set('_', 'matchers', ['matcher_head'])
    let g:deoplete#keyword_patterns = {}
    " let g:deoplete#keyword_patterns.tex = '\\?[a-zA-Z_]\w*'
    let g:deoplete#keyword_patterns.tex = '[^\w|\s][a-zA-Z_]\w*'
  endf

  call neobundle#untap()
endif "}}}
