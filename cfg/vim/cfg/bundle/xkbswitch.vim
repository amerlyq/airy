" You can Fix issue with xkbswitch by removing all its settings.
let g:XkbSwitchEnabled = 1

if has('win32') || has('win64')
    let g:XkbSwitchLib = $VIMHOME . '/bundle/xkb-switch/libxkbswitch.dll'
endif

"" all commented to solve MPogoda's issues
"" enable Insert mode mappings duplicates
let g:XkbSwitchIMappings = ['ru', 'ua']
"let g:XkbSwitchIMappingsSkipFt = ['tex']

let g:XkbSwitchIMappingsTr = {
    \ 'ru':
    \ {'<': 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/'.
    \       'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|',
    \  '>': 'йцукенгшщзхъфывапролджэячсмитьбюё.'.
    \       'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё"№;:?/'},
    \ 'ua':
    \ {'<': 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/'.
    \       'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|',
    \  '>': 'йцукенгшщзхїфівапролджєячсмитьбю’.'.
    \       'ЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ,''"№;:?/'},
    \ }


let g:XkbSwitchNLayout = 'us'
""let g:XkbSwitchILayout = 'us'

let g:XkbSwitchSkipGhKeys = ['gh', 'gH', 'g']
