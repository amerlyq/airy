" Open unite buffer in Insert Mode immediately.
call unite#custom#profile('default', 'context', {
                        \ 'start_insert' : 1
                        \ })
" Directory to store unite configurations.
let g:unite_data_directory = $VIMCACHEDIR . '/unite'
call unite#filters#matcher_default#use(['matcher_fuzzy'])
let g:unite_source_rec_max_cache_files = 0
call unite#custom#source('file_rec,file_rec/async', 'max_candidates', 0)
let g:unite_source_history_yank_enable = 1

"MPogoda thinks it's better change <Leader> to '-'

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
  let g:unite_source_rec_async_command = 'ag --follow --nocolor --nogroup -g ""'
elseif executable('ack-grep')
  " Use ack in unite grep source.
  let g:unite_source_grep_command = 'ack-grep'
  let g:unite_source_grep_default_opts = '--no-heading --no-color -a -H'
  let g:unite_source_grep_recursive_opt = ''
  let g:unite_source_rec_async_command = 'ack -f --nofilter'
endif
