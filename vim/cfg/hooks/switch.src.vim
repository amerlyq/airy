" Cycle between variants
" DISABLED:ALT: 'on_map': [['n', '-', '+']], and use -/+ to switch
let g:switch_mapping = ''
let g:switch_reverse_mapping = ''

autocmd FileType conf let b:switch_custom_definitions = [
  \ ['yes', 'no'],
  \ ['on', 'off'],
  \ [1, 0],
  \]