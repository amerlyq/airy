if neobundle#tap('incsearch.vim') "{{{
  " LIOR: "{{{
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
  map <unique> /  <Plug>(incsearch-forward)
  map <unique> ?  <Plug>(incsearch-backward)
  map <unique> g/ <Plug>(incsearch-stay)
  call neobundle#untap() "}}}

  if neobundle#tap('incsearch.vim') "{{{ 'osyo-manga/vim-anzu'
    map <unique> n <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
    map <unique> N <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)
    call neobundle#untap()
  endif "}}}

  if neobundle#tap('incsearch.vim') "{{{ 'haya14busa/vim-asterisk'
    let g:asterisk#keeppos = 1
    map <unique> *   <Plug>(incsearch-nohl)<Plug>(asterisk-*)
    map <unique> g*  <Plug>(incsearch-nohl)<Plug>(asterisk-g*)
    map <unique> #   <Plug>(incsearch-nohl)<Plug>(asterisk-#)
    map <unique> g#  <Plug>(incsearch-nohl)<Plug>(asterisk-g#)
    " z-prefixed mappings doesn't move the cursor.
    map <unique> z*  <Plug>(incsearch-nohl0)<Plug>(asterisk-z*)
    map <unique> gz* <Plug>(incsearch-nohl0)<Plug>(asterisk-gz*)
    map <unique> z#  <Plug>(incsearch-nohl0)<Plug>(asterisk-z#)
    map <unique> gz# <Plug>(incsearch-nohl0)<Plug>(asterisk-gz#)
    call neobundle#untap()
  endif "}}}
endif "}}}


if neobundle#tap('vim-over') "{{{
  " Over: THINK -- can be useless w/o imap timings, etc
  " USE :<C-f> and then type in command window %s/.../.../g
  " USE :OverCommandLine<CR> and in standalone input your expr: %s/../.../g
  " let g:over_enable_auto_nohlsearch = 1
  " let g:over_enable_cmd_window = 1
  " let g:over_command_line_key_mappings = {}
  " let g:over#command_line#search#enable_incsearch = 1
  " let g:over#command_line#search#enable_move_cursor = 1
  " map <unique> <silent> z; :<C-u>OverCommandLine<CR>
  noremap  <unique><silent> <Leader>c; :<C-u>OverCommandLine<CR>

  nnoremap <unique><silent> <Leader>cc :OverCommandLine %s;;;g<CR><Left><Left>
  xnoremap <unique><silent> <Leader>cc :OverCommandLine  s;;;g<CR><Left><Left>

  nnoremap <unique><silent> <Leader>cm :OverCommandLine %s;;<C-r>/;g<CR><Left><Left>
  xnoremap <unique><silent> <Leader>cm :OverCommandLine  s;;<C-r>/;g<CR><Left><Left>
  call neobundle#untap()
endif "}}}
