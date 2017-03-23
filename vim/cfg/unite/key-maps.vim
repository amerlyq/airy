"{{{1 Window ============================
" NOT: load whole file on each unite-buffer open (might be slow?)

autocmd MyAutoCmd FileType unite call s:unite_wmaps()
" THINK:ALT: exe \"fun! s:unite_wmaps()\n".(readfile(key-maps.vim))."\nendf"

function! s:unite_wmaps()


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
" imap <buffer>  <Tab>   <Plug>(unite_complete)

imap <silent><buffer>  <C-j>  <Plug>(unite_select_next_line)
imap <silent><buffer>  <C-k>  <Plug>(unite_select_previous_line)
imap <silent><buffer>  <C-q>  <Plug>(unite_exit)
inoremap <silent><buffer><expr>  <C-s>   unite#do_action('split')
inoremap <silent><buffer><expr>  <C-v>   unite#do_action('vsplit')


endfunction
