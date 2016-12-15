setl commentstring=> %s
setlocal textwidth=68
setlocal spell

let b:strip_trailing_skip = g:strip_trailing_skip . '|%(^-- $)'
