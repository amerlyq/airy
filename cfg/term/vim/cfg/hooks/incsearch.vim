""" Substitute/Highlight -- with dependent plugins
if !dein#tap('incsearch.vim')| finish |en

" LIOR: "{{{
"   <Tab>/<S-Tab> between search on screen
"   <C-j>/<C-k>   onto next/prev screen
"   <C-l>         start buffer text completion
"   <Right>, <Left> select candidate while completion
" }}}

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

map <unique> /  <Plug>(incsearch-forward)
map <unique> ?  <Plug>(incsearch-backward)
map <unique> g/ <Plug>(incsearch-stay)
for c in ['n', 'N']
  call Map_nxo(c, '<Plug>(incsearch-nohl-'.c.')')
endfor


if dein#tap('incsearch-fuzzy.vim') " Extension: fuzzy/fuzzyspell
  fun! s:cfg_fuzzy(...) abort
    return extend(copy({'converters': [
    \   incsearch#config#fuzzy#converter(),
    \   incsearch#config#fuzzyspell#converter()
    \ ]}), get(a:, 1, {}))
  endf
  noremap <silent><unique><expr>  z/  incsearch#go(<SID>cfg_fuzzy())
  noremap <silent><unique><expr>  z?  incsearch#go(<SID>cfg_fuzzy({'command': '?'}))
  noremap <silent><unique><expr>  z;  incsearch#go(<SID>cfg_fuzzy({'is_stay': 1}))
endif


if dein#tap('vim-anzu')
  "" NOTE: airline ext is good for terminal vim to not jump cursor in cmdline
  " let g:airline#extensions#anzu#enabled = 1
  " SEE unite-anzu
  "   "{Pattern} in matching lines are output in unite.vim
  "   : Unite anzu: {pattern}
  " FIXME: <Plug>(anzu-sign-matchline)
  " NOTE:EXPL: w/o <unique> :: remaps after incsearch
  nmap  n  <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
  nmap  N  <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)
  " EXPL: inside hook to mitigate issue w/ lazy-load for multiple <Plug>-mappings
  fun! dein#hooks.on_source(bundle)
    nmap <silent><unique> <Leader>#
          \ <Plug>(incsearch-nohl)<Plug>(anzu-jump)<Plug>(anzu-mode)
    nmap <silent><unique> <Leader>*
          \ <Plug>(incsearch-nohl)<Plug>(anzu-n)<Plug>(anzu-mode)
  endf
endif


if dein#tap('vim-asterisk')
  " DISABLED: irritates sometimes, plus has highlighting bugs
  ""let g:asterisk#keeppos = 1  " Keep cursor inside match at same position
  " EXPL: z-prefixed mappings doesn't move the cursor.
  for k in ['*', '#', 'g*', 'g#', 'z*', 'z#', 'gz*', 'gz#']
    exe 'map <unique> '.k.' <Plug>(incsearch-nohl'.(k=~#'z'?'0':'').')'.
      \'<Plug>(asterisk-'.k.')<Plug>(anzu-update-search-status-with-echo)'
  endfor
  " Easier to press
  map <unique> z8 <Plug>(incsearch-nohl0)<Plug>(asterisk-z*)
      \<Plug>(anzu-update-search-status-with-echo)
endif
