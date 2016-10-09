"{{{1 OPTS ============================
if has('vim_starting') && has("multi_byte")
  set encoding=utf-8  " For a save and reading
endif

if IsWindows()
  set termencoding=cp1251
elseif &termencoding == ""
  " Force terminal encoding
  let &termencoding = &encoding
  language message C " Use English interface.
endif

setg fileencoding=utf-8
set fileencodings=utf-8,cp1251,cp866

setg fileformat=unix
set fileformats=unix,dos,mac  " Line endings


"{{{1 Locale ============================
set keymap=russian-jcukenwin
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz
" You need reset them after keymap, so very first insert/search
" would be in latin. And then <C-^> toggles these options.
set iminsert=0 imsearch=0
