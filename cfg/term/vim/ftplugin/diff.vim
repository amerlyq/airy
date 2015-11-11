setlocal textwidth=81   " extra char for +/- indicators
setlocal nocursorline   " to not color overlap with highlighted diff regions
if exists('+breakindent') | setl wrap breakindent | setl nowrap | endif
