"{{{1 Search/Replace ============================
if neobundle#tap('ag.vim') "{{{
  let g:ag_highlight=1
  " CHG: all real mappings included into 'after/ftplugin/qf.vim'
  let g:ag_apply_lmappings=0
  let g:ag_apply_qmappings=0
  let g:ag_mapping_message=0
  " let g:ag_qhandler="botleft lopen 7"  "OR: copen 20"
  ": Ag working dir  searching
  " nnoremap <unique> <Leader>* :<C-U>Ag '<C-R>/'<CR>
  nnoremap <unique> <Leader>a :<C-U>Ag -w <C-r>=shellescape('<cword>')<CR><CR>
  vnoremap <unique> <Leader>a :<C-U>Ag -Q '<C-r>=GetVisualSelection(" ")<CR>'<CR>
  ": Ag buffer search
  nnoremap <unique> g<Leader>a :<C-U>AgBuffer -w '<C-R><C-W>'<CR>
  vnoremap <unique> g<Leader>a :<C-U>AgBuffer -Q '<C-R>=GetVisualSelection(" ")<CR>'<CR>
  ": Ag current file searching (currently no jumping -- need Ag >= 0.25 with --vimgrep)
  nnoremap <unique> <Leader>A :<C-U>Ag -w '<C-R><C-W>' %:p<CR>
  vnoremap <unique> <Leader>A :<C-U>Ag -Q '<C-R>=GetVisualSelection(" ")<CR>' %:p<CR>
  let g:ag_prg="ag --smart-case --vimgrep"
  fun! neobundle#hooks.on_source(bundle)
    if split(system("ag --version"), "[ \n\r\t]")[2] <= '0.25.0'
      let g:ag_prg="ag --smart-case --column --nogroup --noheading --ignore tags"
    endif
  endf
  call neobundle#untap()
endif "}}}


"{{{1 Substitute/Highlight ============================
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
  let g:incsearch_cli_key_mappings = { "\<C-y>": {
        \ 'key': "\<C-r>=CopyStringInReg('+',getcmdline())\<CR>\<C-h>",
        \ 'noremap': 1 }}
  map <unique> /  <Plug>(incsearch-forward)
  map <unique> ?  <Plug>(incsearch-backward)
  map <unique> g/ <Plug>(incsearch-stay)
  for c in ['n', 'N']|call Map_nxo(c, '<Plug>(incsearch-nohl-'.c.')')|endfor
  call neobundle#untap() "}}}


  if neobundle#tap('incsearch-fuzzy.vim') "{{{ Extension: fuzzy/fuzzyspell
    fun! s:cfg_fuzzy(...) abort
      return extend(copy({'converters': [
      \   incsearch#config#fuzzy#converter(),
      \   incsearch#config#fuzzyspell#converter()
      \ ]}), get(a:, 1, {}))
    endf
    noremap <silent><unique><expr>  z/  incsearch#go(<SID>cfg_fuzzy())
    noremap <silent><unique><expr>  z?  incsearch#go(<SID>cfg_fuzzy({'command': '?'}))
    noremap <silent><unique><expr>  zg? incsearch#go(<SID>cfg_fuzzy({'is_stay': 1}))
    call neobundle#untap() "}}}
  endif


  if neobundle#tap('vim-anzu') "{{{ 'osyo-manga/vim-anzu'
    "" NOTE: airline ext is good for terminal vim to not jump cursor in cmdline
    let g:airline#extensions#anzu#enabled = 1
    " SEE unite-anzu
    "   "{Pattern} in matching lines are output in unite.vim
    "   : Unite anzu: {pattern}
    " FIXME: <Plug>(anzu-sign-matchline)
    " NOTE:EXPL: w/o <unique> :: remaps after incsearch
    nmap  n  <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
    nmap  N  <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)
    " EXPL: inside hook to mitigate issue w/ lazy-load for multiple <Plug>-mappings
    fun! neobundle#hooks.on_source(bundle)
      nmap <silent><unique> <Leader>#
            \ <Plug>(incsearch-nohl)<Plug>(anzu-jump)<Plug>(anzu-mode)
      nmap <silent><unique> <Leader>*
            \ <Plug>(incsearch-nohl)<Plug>(anzu-n)<Plug>(anzu-mode)
    endf
    call neobundle#untap()
  endif "}}}


  if neobundle#tap('vim-asterisk') "{{{ 'haya14busa/vim-asterisk'
    let g:asterisk#keeppos = 1  " Keep cursor inside match at same position
    " EXPL: z-prefixed mappings doesn't move the cursor.
    for k in ['*', '#', 'g*', 'g#', 'z*', 'z#', 'gz*', 'gz#']
      exe 'map <unique> '.k.' <Plug>(incsearch-nohl'.(k=~#'z'?'0':'').')'.
        \'<Plug>(asterisk-'.k.')<Plug>(anzu-update-search-status-with-echo)'
    endfor
    call neobundle#untap()
  endif "}}}

endif "}}}



"{{{1 Substitution preview/helpers  ====================
if neobundle#tap('vim-over') "{{{
  " STD:TIP: :<C-f> and then type in command window %s/.../.../g
  " LIOR: :OverCommandLine<CR> and in standalone input your expr:
  "   %s/../.../g  OR  /...  OR  %g/.../d
  let g:over_enable_auto_nohlsearch = 1
  let g:over_enable_cmd_window = 0
  " let g:over_command_line_key_mappings = {}
  "" NOTE: this part is somewhat overlaps with incsearch.vim
  let g:over#command_line#search#enable_incsearch = 1
  let g:over#command_line#search#enable_move_cursor = 1
  let s:cmdwrap = 'OverCommandLine %s<CR>'  " Used to wrap subs below
  " DISABLED: because of bug in 'vimoutliner' mappings
  " noremap  <unique><silent>  :  :OverCommandLine /<CR>
  call neobundle#untap()
endif "}}}
"ALSO:STD:ALWAYS: {{{
  " DEV: '21,c': v:count for ',c' -- \2\1, use <expr> mapping, add backslash
  " BUG: adds visual markers '<, '> before subs.
  fun! SubsCount()
    let rhs = (v:count ? substitute(string(v:count), '.', '\\&', 'g') : '')
    return l:rhs
  endfun
  let s:subs = {
  \ '<Leader>c' : 's;;<C-r>=SubsCount()<CR>;g',
  \ '<Leader>C' : 'g//',
  \ '<Leader>R' : 'v//',
  \ '[Replace]w': 's::<C-r><C-w>:g',
  \ '[Replace]y': 's::<C-r>":g',
  \ '[Replace]+': 's::<C-r>+:g',
  \ '[Replace]m': 's;;<C-r>/;g',
  \ '[Replace]v': '<C-u>s@@<C-r>=GetVisualSelection("")<CR>@g',
  \ '[Replace]s': '<C-u>s@<C-r>=GetVisualSelection("")<CR>@@g',
  \ '[Replace]e': 's;;;g<CR>',
  \ '[Replace]d': 'g//d<CR>',
  \ '[Replace]f': 'v//d<CR>',
  \} " norm!, etc
  for [c, r] in items(s:subs) | if maparg(c) ==# '' | for m in ['n','x']
    exe printf('%snoremap <silent><unique>  %s  :'.(
          \   exists('s:cmdwrap') && (r!~?'<CR>$') ? s:cmdwrap : '%s').'%s',
          \ m, c, (m=='n'?'%':'').r, ((r=~#'\Wg$') ? '<Left><Left>' : '') )
  endfor | endif | endfor
  "}}}
"}}} --Substitution--
