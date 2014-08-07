" Open unite buffer in Insert Mode immediately.
let g:unite_enable_start_insert = 1

" Directory to store unite configurations.
let g:unite_data_directory = $VIMCACHEDIR . '/unite'

" Replaces fuzzyfinder
nnoremap <leader>o :<C-u>Unite -buffer-name=files file_rec/async:!<cr>
" Replaces NERDTree
nnoremap <leader>f :<C-u>Unite -buffer-name=files file<cr>
nnoremap <leader>F :<C-u>VimFiler<cr>

" Quickly find a buffer
nnoremap <leader>b :<C-u>Unite -quick-match -buffer-name=buffers buffer<cr>

nnoremap <leader>/ :<C-u>Unite -buffer-name=grep grep:.<cr>

nnoremap <leader>l :<C-u>Unite -buffer-name=lines line<cr>
nnoremap <leader>; :<C-u>Unite -buffer-name=commands command<cr>
nnoremap <leader>: :<C-u>Unite -buffer-name=commands history/command<cr>

nnoremap <leader>m :<C-u>Unite -buffer-name=mrus file_mru<cr>

let g:unite_source_history_yank_enable = 1
nnoremap <leader>y :<C-u>Unite -buffer-name=yanks history/yank<cr>

nnoremap <leader>h :<C-u>Unite -buffer-name=help help<cr>

autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()
  " Overwrite settings.
  imap <silent><buffer><expr> <C-s> unite#do_action('split')
  imap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
  " Enable navigation with control-j and control-k in insert mode
  imap <silent><buffer> <C-j> <Plug>(unite_select_next_line)
  imap <silent><buffer> <C-k> <Plug>(unite_select_previous_line)
  " Quit from insert mode
  imap <silent><buffer> <C-q> <Plug>(unite_exit)
endfunction

if executable('ag')
  " Use ag in unite grep source.
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts =
  \ '--line-numbers --nocolor --nogroup --hidden --ignore ' .
  \  '''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
  let g:unite_source_grep_recursive_opt = ''
elseif executable('ack-grep')
  " Use ack in unite grep source.
  let g:unite_source_grep_command = 'ack-grep'
  let g:unite_source_grep_default_opts =
  \ '--no-heading --no-color -a -H'
  let g:unite_source_grep_recursive_opt = ''
endif
