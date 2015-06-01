" LIOR:
"   <Tab>/<S-Tab> between search on screen
"   <C-j>/<C-k>   onto next/prev screen
"   <C-l>         start buffer text completion
"   <Right>, <Left> select candidate while completion


" Options
let g:incsearch#smart_backward_word=1
let g:incsearch#separate_highlight = 0
let g:incsearch#consistent_n_direction = 0
" See: :messages -- for history
let g:incsearch#do_not_save_error_message_history = 1
" Prefer literal search. Use most magic \v directly when using regexes.
let g:incsearch#magic = '\M'
" Highlight auto-disable when moving
let g:incsearch#auto_nohlsearch = 1


" Main
map <unique> /  <Plug>(incsearch-forward)
map <unique> ?  <Plug>(incsearch-backward)
map <unique> g/ <Plug>(incsearch-stay)


" Index: Integration with 'osyo-manga/vim-anzu'
map <unique> n <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
map <unique> N <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)

" Smart: Integration with 'haya14busa/vim-asterisk'
let g:asterisk#keeppos = 1
" z-prefixed mappings doesn't move the cursor.
map <unique> *   <Plug>(incsearch-nohl)<Plug>(asterisk-*)
map <unique> g*  <Plug>(incsearch-nohl)<Plug>(asterisk-g*)
map <unique> #   <Plug>(incsearch-nohl)<Plug>(asterisk-#)
map <unique> g#  <Plug>(incsearch-nohl)<Plug>(asterisk-g#)
map <unique> z*  <Plug>(incsearch-nohl0)<Plug>(asterisk-z*)
map <unique> gz* <Plug>(incsearch-nohl0)<Plug>(asterisk-gz*)
map <unique> z#  <Plug>(incsearch-nohl0)<Plug>(asterisk-z#)
map <unique> gz# <Plug>(incsearch-nohl0)<Plug>(asterisk-gz#)


" Over: use :OverCommandLine<CR> and input your expr: %s/../.../g
let g:over_command_line_key_mappings = {}
let g:over#command_line#search#enable_move_cursor = 0
" let g:over_enable_auto_nohlsearch = 1
" let g:over_enable_cmd_window = 1
map <unique> <silent> z; :<C-u>OverCommandLine<CR>

