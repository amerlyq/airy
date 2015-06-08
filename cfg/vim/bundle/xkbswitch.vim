" You can Fix issue with xkbswitch by removing all its settings.
let g:XkbSwitchEnabled = 1

if has('win32') || has('win64')
    let g:XkbSwitchLib = $CACHE . '/bundle/xkb-switch/libxkbswitch.dll'
endif

"" all commented to solve MPogoda's issues
"" enable Insert mode mappings duplicates
let g:XkbSwitchIMappings = ['ru', 'ua']
"let g:XkbSwitchIMappingsSkipFt = ['tex']

"" TODO: disable if no custom layout detected
let g:XkbCustom = ['1234567890-=!@#$%^&*()_+', '!".;%/:,-?_=1234567890_+']

let g:XkbSwitchIMappingsTr = {
    \ 'ru':
    \ {'<': 'qwertyuiop[]asdfghjkl;''zxcvbnm,.`/' . g:XkbCustom[0] .
    \       'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~@#$^&|',
    \  '>': 'йцукенгшщзхъфывапролджэячсмитьбюё.' . g:XkbCustom[1] .
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
