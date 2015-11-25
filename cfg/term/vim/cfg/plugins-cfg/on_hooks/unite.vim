"{{{1 Window ============================

" if !exists('g:loaded_unite') | finish | endif
autocmd MyAutoCmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()
  " Overwrite settings.
  nmap <buffer> x     <Plug>(unite_quick_match_jump)
  nnoremap <silent><buffer><expr> !    unite#do_action('startinsert')
  nnoremap <silent><buffer><expr> cd   unite#do_action('lcd')
  nnoremap <silent><buffer> <Tab>     <C-w>w

  " SMART actions
  nnoremap <silent><buffer><expr> r
        \ (unite#get_current_unite().profile_name ==# '^search' ?
        \   unite#do_action('replace') : unite#do_action('rename'))

  " TOGGLE options
  nnoremap <buffer><expr> S
      \ unite#mappings#set_current_sorters(
      \   empty(unite#mappings#get_current_sorters()) ?
      \     ['sorter_reverse'] : [])
  nnoremap <buffer><expr> cof
      \ unite#mappings#set_current_matchers(
      \   empty(unite#mappings#get_current_matchers()) ?
      \     ['matcher_fuzzy'] : [])

  " INSERT navigation and actions
  imap <buffer>   <BS>   <Plug>(unite_delete_backward_path)
  imap <buffer>  <C-w>   <Plug>(unite_delete_backward_path)
  imap <buffer>    jj    <Plug>(unite_insert_leave)
  imap <buffer>    ,s    <Plug>(unite_insert_leave)
  imap <buffer>  <Tab>   <Plug>(unite_complete)

  imap <silent><buffer>  <C-j>  <Plug>(unite_select_next_line)
  imap <silent><buffer>  <C-k>  <Plug>(unite_select_previous_line)
  imap <silent><buffer>  <C-q>  <Plug>(unite_exit)
  inoremap <silent><buffer><expr>  <C-s>   unite#do_action('split')
  inoremap <silent><buffer><expr>  <C-v>   unite#do_action('vsplit')

endfunction


" Default configuration. Start in insert mode.
" 'prompt': '» '
let default_context = { 'vertical': 0, 'short_source_names': 1 }
call unite#custom#profile('default', 'context', default_context)
call unite#custom#profile('action', 'context', { 'start_insert': 1 })



"{{{1 Settings ============================
" Directory to store unite configurations.
let g:unite_data_directory = $CACHE . '/unite'
let g:unite_ignore_source_files = []
let g:unite_source_rec_max_cache_files = -1
let g:unite_source_history_yank_enable = 1


"{{{1 Filters ============================
call unite#filters#sorter_default#use(['sorter_rank'])  " sorter_length
call unite#filters#matcher_default#use(['matcher_fuzzy'])


"{{{1 Sources ============================
call unite#custom#source('file_rec,file_rec/async', 'max_candidates', 0)


"{{{1 Menus ============================
let g:unite_source_menu_menus = {}  " For unite-menu.
let g:unite_source_menu_menus.unite = {'description': 'Start unite sources'}
let g:unite_source_menu_menus.unite.command_candidates = {
      \       'history'    : 'Unite history/command',
      \       'quickfix'   : 'Unite qflist -no-quit',
      \       'resume'     : 'Unite -buffer-name=resume resume',
      \       'directory'  : 'Unite -buffer-name=files '.
      \             '-default-action=lcd directory_mru',
      \       'mapping'    : 'Unite mapping',
      \       'message'    : 'Unite output:message',
      \       'scriptnames': 'Unite output:scriptnames',
      \     }


"{{{1 Integration ============================
" Use ag in unite grep source.
"   https://github.com/ggreer/the_silver_searcher
if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts =
        \ '-S --vimgrep --hidden' .
        \   " --ignore '.git' --ignore '.hg'" .
        \   " --ignore '.svn' --ignore '.bzr'"
  let g:unite_source_grep_recursive_opt = ''
  let g:unite_source_rec_async_command = 'ag --follow --nocolor --nogroup --hidden -g ""'
endif
" ALSO:
" ack-grep -- http://beyondgrep.com/
" pt(Go) -- https://github.com/monochromegane/the_platinum_searcher
" ALT: for jap (SEE:Shougo)
" hw -- https://github.com/tkengo/highway
"   https://github.com/mattn/jvgrep
