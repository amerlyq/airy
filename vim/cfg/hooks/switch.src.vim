" Cycle between variants
" DISABLED:ALT: 'on_map': [['n', '-', '+']], and use -/+ to switch
let g:switch_mapping = '<CR>'
let g:switch_reverse_mapping = '<BS>'

autocmd FileType conf let b:switch_custom_definitions = [
  \ {'\<yes\>': 'no', '\<no\>': 'yes'},
  \ {'\<on\>': 'off', '\<off\>': 'on'},
  \]
" \ {'\<1\>': '0', '\<0\>': '1'},
" \ { ':\(\k\+\)\s\+=>': '\1:', '\<\(\k\+\):': ':\1 =>' },

if !exists('g:switch_custom_definitions')
  let g:switch_custom_definitions = []
endif

"" WF: from everywhere-notches
" switch#NormalizedCase(['one', 'two']),
" switch#NormalizedCaseWords(['five', 'six']),
let g:switch_custom_definitions +=
  \[ switch#Words(['TODO', 'DONE', 'WARN'])
  \, switch#Words(['THINK', 'IDEA'])
  \, switch#Words(['ALT', 'OR', 'CASE'])
  \, switch#Words(['DEV', 'ENH', 'RFC'])
  \]
