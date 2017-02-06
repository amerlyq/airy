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

" WARN: can't remap from symbols/numbers -- causes double-remapping
" BUG: don't work remapping for ',' and ';' (:help insists, escaping must work)
let &langmap = ''
  \.'ЙЦУКЕНГШЩЗХЪ'.';'
  \.'QWERTYUIOP{}'
  \.','
  \.'ФЫВАПРОЛДЖЭ'.';'
  \.'ASDFGHJKL:"'
  \.','
  \.'ЯЧСМИТЬБЮЁ'.';'
  \.'ZXCVBNM<>?'
  \.','
  \.'йцукенгшщзхъ'.';'
  \.'qwertyuiop[]'
  \.','
  \.'фывапролджэ'.';'
  \.'asdfghjkl\;'''
  \.','
  \.'ячсмитьбюё'.';'
  \.'zxcvbnm\,./'

" WARN: place after &langmap/&keymap to reset default lang to latin
" NOTE: <C-^> toggles these options.
set iminsert=0 imsearch=0
