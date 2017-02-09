" WARN: must be outside -- to redefine functions on script first source
let g:xkb_use_monitor = 0  " TEMP: disabled, bugged

let s:kbdd_svc='ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.'
let s:kbdd_set='dbus-send --dest=' . s:kbdd_svc . 'set_layout uint32:'
let s:kbdd_get='dbus-send --print-reply=literal --dest='
  \. s:kbdd_svc . 'getCurrentLayout'
let s:kbdd_mon = ['dbus-monitor', '--profile',
  \ 'interface=ru.gentoo.kbdd,member=layoutChanged']

let s:kbdd_running = 0
let s:kbdd_guard = 0
let s:kbdd_insert = &insertmode

" ALT: use python to monitor dbus events
"   https://github.com/qnikst/kbdd/wiki/Usecases
"   https://dbus.freedesktop.org/doc/dbus-python/doc/tutorial.html
"   https://github.com/arunchaganty/vimjuta/blob/master/misc/vim-dbus.py

" THINK:(create my own) ~/.vim/keymap/russian-amer.vim

fun! xkb#get()
  return get(split(system(s:kbdd_get)), -1)
endf

fun! xkb#set(i)
  let s:kbdd_guard += 1
  return system(s:kbdd_set . a:i)
endf

fun! xkb#show()
  if g:xkb.insert == g:xkb.normal| return '' |en
  return get(g:xkb.langs, g:xkb.insert, '??')
endf


if exists('*jobstart') && exists('g:xkb_use_monitor') && g:xkb_use_monitor

  fun! xkb#enter()
    let s:kbdd_insert = 1
    let l = g:xkb.insert

    " BUG: for ua/ukr l==2 -- maybe out of bounds for im* VAR
    " BAD: layout switch by dbus has no effect if 'im*' enabled
    let &iminsert = l
    let &imsearch = l
    call xkb#set(l)
  endf

  fun! xkb#leave()
    let s:kbdd_insert = 0
    let l = g:xkb.normal
    let &iminsert = l
    let &imsearch = l
    call xkb#set(l)
  endf

  " HACK: used when FocusLost/FocusGain unavailable (nvim in tmux in st)
  " NOTE: mechanics to use dbus-monitor only in active vim instance
  "   => MAYBE:BUG when fast switching instances --
  fun! xkb#moved()
    au! xkb_kbdd CursorMoved
    let s:kbdd_running = 1
  endf

  fun! xkb#hold()
    let s:kbdd_running = 0
    au xkb_kbdd CursorMoved *  call xkb#moved()
  endf

else  " exists('*jobstart')
  " OBSOLETE: single-thread variant, intermitten bugs on mode change
  " ATT: can't combine with 'im*' -- dbus has no effect on them in Insert

  fun! xkb#enter()
    let curr = xkb#get()
    if curr != g:xkb.normal
      let g:xkb.insert = curr
    en
    let s:kbdd_insert = 1
    if curr != g:xkb.insert
      call xkb#set(g:xkb.insert)
    en
  endf

  fun! xkb#leave()
    let curr = xkb#get()
    if curr != g:xkb.insert
      let g:xkb.insert = curr
    en
    let s:kbdd_insert = 0
    if curr != g:xkb.normal
      call xkb#set(g:xkb.normal)
    en
  endf

  " BAD: 'system()' in '#get()' results in cursor blinking on CursorHold
  fun! xkb#hold()
    " let curr = xkb#get()
    " if curr != g:xkb.normal
    "   " Push layout change to Insert and reset Normal back to default
    "   let g:xkb.insert = curr
    "   call xkb#set(g:xkb.normal)
    " en
  endf

endif


" BETTER: allows to switch Insert layout back to eng w/o leaving Normal mode
" Event Sources:
"   keyboard: switch layout
"   kbdd: individual window layout restore
"   vim: reflected xkb#set()
fun! s:kbdd_handler(job_id, data, event)

  " TEMP:DEBUG
  echo '['.s:kbdd_running.'] ('.s:kbdd_guard . ') : '
      \. mode() . '/' . s:kbdd_insert . ' -- ' . g:xkb.insert

  " Guard for multiple vim instances with dbus-monitor
  if s:kbdd_running <= 0| return |en

  " TEMP:USAGE: let str = self.name.' stdout: '.join(a:data)
  if a:event != 'stdout'| return |en

  " NOTE: guard against recursive reflected switching by xkb#set()
  " BUG: s:kbdd_guard >> 0 (may become 3 or even 7) -- due to multiple vim
  " instances with multiple kbdd monitor jobs
  if s:kbdd_guard > 0| let s:kbdd_guard = 0 | return |en

  " BUG: even unfocused job monitors lang changes in other vim instances !!!
  "   => NEED: pause job when unfocused
  let l = xkb#get()
  let g:xkb.insert = l
  let &iminsert = l
  let &imsearch = l
  " echo g:xkb.insert
  " if !s:kbdd_insert && g:xkb.insert != g:xkb.normal
  "   call xkb#set(g:xkb.normal)
  " en
endf


fun! xkb#init()
  let g:xkb = { 'insert': 0, 'normal': 0, 'langs': ['us', 'ru', 'ua'] }

  augroup xkb_kbdd
    au!
    au InsertEnter,CmdwinEnter * call xkb#enter()
    au InsertLeave,CmdwinLeave * call xkb#leave()
    au CursorHold *  call xkb#hold()
    " autocmd CursorMoved *
    "   => cmp curr with prev dfl lang -- if changed
    "   -- do the same as in hold, then remove 'moved' hook
  augroup END

  " MODERN: background monitoring callback
  if exists('*jobstart') && exists('g:xkb_use_monitor') && g:xkb_use_monitor
    let s:kbdd_cb = {
      \ 'name': 'kbdd.vim',
      \ 'on_stdout': function('s:kbdd_handler'),
      \ 'on_stderr': function('s:kbdd_handler'),
      \ 'on_exit'  : function('s:kbdd_handler'),
      \}
    let s:kbdd_job = jobstart(s:kbdd_mon, s:kbdd_cb)
    let s:kbdd_running = 1
  endif
endf
