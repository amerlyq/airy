setlocal textwidth+=1 " extra char for +/- indicators

let s:diff_mappings = {
      \ 'q' : ':#close<CR>',
\ }

for key_map in items(s:diff_mappings)
  exec printf("nnoremap <buffer><nowait><silent> %s %s", get(key_map, 0)
                    \ , substitute(get(key_map, 1), '#', b:wPref, 'g'))
endfor
