""" Substitution preview/helpers -- with DFL mappings

if dein#tap('vim-over')
  " STD:TIP: :<C-f> and then type in command window %s/.../.../g
  " LIOR: :OverCommandLine<CR> and in standalone input your expr:
  "   %s/../.../g  OR  /...  OR  %g/.../d
  let g:over_enable_auto_nohlsearch = 1
  let g:over_enable_cmd_window = 0
  " let g:over_command_line_key_mappings = {}
  "" NOTE: this part is somewhat overlaps with incsearch.vim
  let g:over#command_line#search#enable_incsearch = 1
  let g:over#command_line#search#enable_move_cursor = 1
  let s:cwrap = 'OverCommandLine %s<CR>'  " Used to wrap subs below
  " DISABLED: because of bug in 'vimoutliner' mappings
  " noremap  <unique><silent>  :  :OverCommandLine /<CR>
endif


" DEV: '21,c': v:count for ',c' -- \2\1, use <expr> mapping, add backslash
" BUG: adds visual markers '<, '> before subs.
fun! SubsCount()
  let rhs = (v:count ? substitute(string(v:count), '.', '\\&', 'g') : '')
  return l:rhs
endf

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
  exe printf('%snoremap '.(exists('s:cwrap') ? '<silent>' : '').'<unique> '
        \.'%s :'.(exists('s:cwrap') && (r!~?'<CR>$') ? s:cwrap : '%s').'%s',
        \ m, c, (m=='n'?'%':'').r, ((r=~#'\Wg$') ? '<Left><Left>' : '') )
endfor | endif | endfor
