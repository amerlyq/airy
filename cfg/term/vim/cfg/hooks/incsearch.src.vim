""" Substitute/Highlight -- with dependent plugins

"   <Tab>/<S-Tab> between search on screen
"   <C-j>/<C-k>   onto next/prev screen
"   <C-l>         start buffer text completion
"   <Right>, <Left> select candidate while completion

let g:incsearch#smart_backward_word=1
let g:incsearch#separate_highlight = 0
let g:incsearch#consistent_n_direction = 0
" SEE :messages -- for history
let g:incsearch#do_not_save_error_message_history = 1
" Prefer literal search. Use most magic \v directly when using regexes.
" let g:incsearch#magic = '\m'
" Highlight auto-disable when moving
let g:incsearch#auto_nohlsearch = 1
let g:incsearch_cli_key_mappings = { "\<C-y>": {
      \ 'key': "\<C-r>=CopyStringInReg('+',getcmdline())\<CR>\<C-h>",
      \ 'noremap': 1 }}
