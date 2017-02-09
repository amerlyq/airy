setlocal textwidth=81   " extra char for +/- indicators
setlocal nocursorline   " to not color overlap with highlighted diff regions

" BAD: will affect all other opened buffers!
let g:strip_empty_end_lines = 0
let g:strip_trailing_space = 0
