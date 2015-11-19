"GoToDefinitionElseDeclaration
" nnoremap <leader>jd :YcmCompleter GoTo<CR>

" YCM won't load on startup
" Now it is loaded as starting argument to vim inside of alias
" use ycm to load vim with YouCompleteMe
"let g:loaded_youcompleteme = 1

" if you using Vundle
" you could use something like this
" autocmd FileType c++ Bundle 'Valloric/YouCompleteMe'
" and just replace the type you need instead of c++

let g:ycm_confirm_extra_conf = 0  " Extremely dangerous! But...
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_seed_identifiers_with_syntax = 1
let g:ycm_filepath_completion_use_working_dir = 1
let g:ycm_use_ultisnips_completer = 0  " I use incompatible neosnippet

"" DISABLED: irritates
" let g:ycm_add_preview_to_completeopt = 1
" let g:ycm_autoclose_preview_window_after_completion = 1
" let g:ycm_autoclose_preview_window_after_insertion = 1

let g:ycm_complete_in_comments = 1
let g:ycm_complete_in_strings = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_collect_identifiers_from_comments_and_strings = 1

let g:ycm_key_invoke_completion = '<C-Space>'
" let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']

" [ 'same-buffer', 'horizontal-split', 'vertical-split', 'new- tab', 'new-or-existing-tab' ]
let g:ycm_goto_buffer_command = 'same-buffer'

let g:ycm_filetype_whitelist = { 'c': 1, 'cpp': 1 }

" let g:ycm_extra_conf_globlist = ['~/.vim/bundle/YouCompleteMe/cpp/ycm/*','!~/*']

" let g:ycm_global_ycm_extra_conf = '~/.vim/ycm_fallback.conf'
" let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
