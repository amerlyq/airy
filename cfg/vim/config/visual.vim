" visually select the text that was last edited or pasted
nnoremap gv `[v`]

" visually select a search result
nnoremap g/ //e<cr>v??<cr>


" reselect visual block after indent
vnoremap < <gv
vnoremap > >gv
