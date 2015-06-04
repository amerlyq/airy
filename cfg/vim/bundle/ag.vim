if split(system("ag --version"), "[ \n\r\t]")[2] > '0.25.0'
  let g:ag_prg="ag --vimgrep --smart-case"
else
  let g:ag_prg="ag --column --nogroup --noheading --ignore tags --smart-case"
endif

" let g:aghighlight=1

" Disable default map: all real mappings included into 'after/ftplugin/qf.vim'
let g:ag_apply_lmappings=0
let g:ag_apply_qmappings=0


" let g:ag_lhandler="botright lopen 7"
" let g:ag_qhandler="botleft lopen 7"
"OR: copen 20"

let g:ag_mapping_message=0
