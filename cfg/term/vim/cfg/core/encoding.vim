"{{{1 OPTS ============================
if has('vim_starting') && has("multi_byte")
  set encoding=utf-8  " For a save and reading
endif

if has('multi_byte_ime')
  set iminsert=0 imsearch=0
endif

if IsWindows()
  set termencoding=cp1251
elseif &termencoding == ""
  " Force terminal encoding
  let &termencoding = &encoding
endif

setg fileencoding=utf-8
set fileencodings=utf-8,cp1251,cp866

setg fileformat=unix
set fileformats=unix,dos,mac  " Line endings


"{{{1 CMDS ============================
"" Opening with a specific character code again.
command! -bang -bar -complete=file -nargs=? Eutf8
      \ edit<bang> ++enc=utf-8 <args>
command! -bang -bar -complete=file -nargs=? Eutf16
      \ edit<bang> ++enc=ucs-2le <args>
command! -bang -bar -complete=file -nargs=? Eutf16be
      \ edit<bang> ++enc=ucs-2 <args>

"" Appoint a line feed.
command! -bang -complete=file -nargs=? Wunix
      \ write<bang> ++fileformat=unix <args> | edit <args>
command! -bang -complete=file -nargs=? Wdos
      \ write<bang> ++fileformat=dos <args> | edit <args>
command! -bang -complete=file -nargs=? Wmac
      \ write<bang> ++fileformat=mac <args> | edit <args>
