"GoToDefinitionElseDeclaration
nnoremap <leader>jd :YcmCompleter GoTo<CR>

" YCM won't load on startup
" Now it is loaded as starting argument to vim inside of alias
" use ycm to load vim with YouCompleteMe
"let g:loaded_youcompleteme = 1

" if you using Vundle
" you could use something like this
" autocmd FileType c++ Bundle 'Valloric/YouCompleteMe'
" and just replace the type you need instead of c++

let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_complete_in_comments = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_seed_identifiers_with_syntax = 1

let g:ycm_add_preview_to_completeopt = 1
let g:ycm_autoclose_preview_window_after_completion = 1
" let g:ycm_autoclose_preview_window_after_insertion = 1

" YCM
"   let g:ycm_extra_conf_globlist = ['~/.vim/bundle/YouCompleteMe/cpp/ycm/*','!~/*']

    let g:ycm_global_ycm_extra_conf = '~/.vim/ycm_fallback.conf'
    " let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'

" Syntastic
"    let g:syntastic_c_checkers=['make']
"    let g:syntastic_always_populate_loc_list = 1
"    let g:syntastic_check_on_open=1
"    let g:syntastic_enable_signs=1
"    let g:syntastic_error_symbol = '✗'
"    let g:syntastic_warning_symbol = '⚠'
"    set statusline+=%#warningmsg#
"    set statusline+=%{SyntasticStatuslineFlag()}
"    set statusline+=%*gbar
