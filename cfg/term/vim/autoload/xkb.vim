let s:svc_kbdd='ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.'

fun! xkb#get()
  return system('qdbus '.s:svc_kbdd.'getCurrentLayout')
endf

fun! xkb#set(i)
  return system('dbus-send --dest='.s:svc_kbdd.'set_layout uint32:'.a:i)
endf

fun! xkb#enter()
  call xkb#set(g:xkb.insert)
endf

fun! xkb#leave()
  let g:xkb.insert = xkb#get()
  call xkb#set(g:xkb.normal)
endf

fun! xkb#show()
  return get(g:xkb.langs, g:xkb.insert, '??')
endf


fun! xkb#init()
  let g:xkb = { 'insert': 0, 'normal': 0, 'langs': ['us', 'ru', 'ua'] }
  augroup xkb_kbdd
    au!
    autocmd InsertEnter,CmdwinEnter * call xkb#enter()
    autocmd InsertLeave,CmdwinLeave * call xkb#leave()
  augroup END
endf
