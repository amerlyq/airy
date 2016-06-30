" STD:TIP: :<C-f> and then type in command window %s/.../.../g
"   FIND: how to execute group of lines?
"   -- individual mappings -- to execute on <CR>/etc despite vim-sneak?

" DISABLED: because of bug in 'vimoutliner' mappings
" noremap  <unique><silent>  :  :OverCommandLine /<CR>


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
  exe printf(m.'noremap '.(exists('g:subs_wrap') ? '<silent>' : '').'<unique> '
    \.c.' :'.(exists('g:subs_wrap') && (r!~?'<CR>$') ? g:subs_wrap : '%s').'%s'
    \, (m=='n'?'%':'').r, ((r=~#'\Wg$') ? '<Left><Left>' : '') )
endfor | endif | endfor
