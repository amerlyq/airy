" only  " Force the at the bottom, but then gh/gl disabled?

let s:help_mappings = {
      \ 'gH' : ':norm gh<CR>',
      \ 'gL' : ':norm gl<CR>',
      \ 'gh' : '<C-T>',
      \ 'gl' : 'g<C-]>',
\ }

let s:fmt_key = "nnoremap <buffer><nowait><silent> %s %s"
for [k, v] in items(s:help_mappings)
  exe printf(s:fmt_key, k, v)
endfor
