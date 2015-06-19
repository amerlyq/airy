" Сброс iminsert и imsearch необходим, чтобы самый первый раз вставка и ввод
" паттерна поиска начались с латиницы. По сути, Ctrl+^ переключает эти
" значения между 0 и 1.
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

