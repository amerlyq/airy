" Old
let g:tcommentLineC = '// %s'

" Current
let g:tcomment#replacements_c = {
            \     '/*': '#<{(|',
            \     '*/': '|)}>#',
            \ }

let g:tcommentLineC_fmt = {
            \ 'commentstring_rx': '\%%(// %s\|/* %s */\)',
            \ 'commentstring': '// %s',
            \ 'rxbeg': '\*\+',
            \ 'rxend': '',
            \ 'rxmid': '',
            \ 'replacements': g:tcomment#replacements_c
            \ }

