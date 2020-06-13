" ⌇!%:nu
" SPDX-FileCopyrightText: 2020 Dmytro Kolomoiets <amerlyq@gmail.com>
" SPDX-License-Identifier: GPL-3.0-only
" SPDX-PackageName: vim-xtref
" SPDX-PackageSummary: timestamp-based cross-refs manipulation and tagging
"

let g:xtref = {}
let g:xtref.aura = $HOME."/aura"   " main dir of your global knowledge base
let g:xtref.tagfile = 'xtref.tags' " separate DB for xrefs to prevent

let g:xtref.anchor_pfx = '⌇'
let g:xtref.refer_pfx = '※'
let g:xtref.markers = [g:xtref.anchor_pfx, g:xtref.refer_pfx]

" TODO: support for nanoseconds tail
" ALT:(queue): $ r.vim-xtref -pp $ ALT:(generic): '\S{3,20}\ze\s?'
let s:r_z85 = '[-0-9a-zA-Z.:+=^!/*?&<>()\[\]{}@%$#]{5}'
let s:r_braille = '[\u2800-\u28FF]{4}'
let g:xtref.r_addr = '('. s:r_z85 .'|'. s:r_braille .')'
let g:xtref.r_anchor = g:xtref.anchor_pfx . g:xtref.r_addr
let g:xtref.r_refer = g:xtref.refer_pfx . g:xtref.r_addr


" NOTE: xref artifact ※unReK
digraph xa 8967  " ⌇
digraph xr 8251  " ※

augroup filetypedetect
  exe 'au! BufRead,BufNewFile '. g:xtref.tagfile .' edit ++enc=utf8'
augroup END

fun! xtref#vsel()
  let [lbeg, cbeg] = getpos("'<")[1:2]
  let [lend, cend] = getpos("'>")[1:2]
  let lines = getline(lbeg, lend)
  if len(lines) == 0
      return ''
  endif
  let lines[-1] = lines[-1][: cend - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][cbeg - 1:]
  return join(lines, "\n")
endf

fun! xtref#copy(xtref, ...)
  call setreg(get(a:,2,'+'), get(a:,1,' ') . a:xtref, 'c')
endf

fun! xtref#new(...)
  "" DEPRECATED:(z85):
  " let xts = printf('%08x', call('strftime', ['%s'] + a:000))
  " let xts = systemlist('xxd -p -r | basenc --z85 | rev', xts)[0]
  "" ALT:PERF: systemlist('r.vim-xtref '.get(a:,1))[0]
  let xts = substitute(printf('%08x', strftime('%s')), '..', '\=nr2char("0x28".submatch(0))', 'g')
  call xtref#copy(g:xtref.refer_pfx . xts)
  return g:xtref.anchor_pfx . xts
endf


" ALT: use match(strpart(join(rgx,'|')...))
fun! xtref#lseek(expr, needles, start)
  let fn = 'strridx(a:expr,v:val,a:start)'
  let err = -1
  let i = max(filter(map(copy(a:needles), fn), 'v:val>=0') + [err])
  return (i == err) ? -1 : i
endf

fun! xtref#rseek(expr, needles, start)
  let fn = 'stridx(a:expr,v:val,a:start)'
  let err = len(a:expr)+1
  let i = min(filter(map(copy(a:needles), fn), 'v:val>=0') + [err])
  return (i == err) ? -1 : i
endf

" NOTE: seek nearest xtref from cursor left/right
"   INFO:ALT: expand('<cWORD>') don't support glued train of anchors/referals
" WARN! regular tags will be always ignored
"   TODO: provide for them separate keybindings
fun! xtref#get(visual)
  if a:visual
    let [l,c] = [xtref#vsel(), 0]
  else
    let [l,c] = [getline('.'), col('.')-1]
  endif

  let b = xtref#lseek(l, g:xtref.markers, c)
  let e = xtref#rseek(l, g:xtref.markers, c)
  if b<0 && e<0 | return ['', 0] |en

  if b>0 && e>0
    " NOTE: we must compare nearest 'ends' :: (e-c < c-(end_of_b))
    " NOTE: prefer left entry when placed in perfect middle :: [AAA BBB]
    let s = match(l, '\s', b)
    let eob = (s>=0 && s<e) ? s : e
    if e-c < c-eob | let b = e |en
  elseif b<0
    let b = e
  endif

  let e = xtref#rseek(l, g:xtref.markers, b+1)
  if e<0 | let e = len(l) |en

  let s = match(l, '\s', b)
  let len = (s>=0 && s<e) ? s-b : e-b

  return [strpart(l, b, len), b-c]
endf

fun! xtref#replace(visual, sub)
" fun! xtref#replace(...)
"   let [x, off] = xtref#get()
  let [x, off] = xtref#get(a:visual)
  if empty(x) | return |en
  let b = col('.')-1 + off
  let e = b + len(x)
  let l = getline('.')
  call setline('.', (b>0 ? l[0:b-1] : '') . a:sub . l[e:])
endf

fun! xtref#strip(xloci)
  let [x, off] = a:xloci
  let [a,r] = g:xtref.markers
  let pfx = strcharpart(x, 0, 1)
  if pfx ==# a || pfx ==# r | let x = strcharpart(x, 1) | en
  return x
endf

fun! xtref#invert(xloci)
  let [x, off] = a:xloci
  let pfx = strcharpart(x, 0, 1)
  " ALT: keep regular tags untouched = (pfx==a ? r : pfx==r ? a : pfx)
  let [a,r] = g:xtref.markers
  if pfx !=# a && pfx !=# r | return expand('<cword>') | en
  return (pfx ==# a ? r : a) . strcharpart(x, 1)  " fnameescape()
endf

"" NICE: use "r.vim-xtref" as SPOT
" VIZ:(fmt): braille hex dt date utc unix z85 z85r
fun! xtref#to_fmt(fmt, xloci)
  let [xts, off] = a:xloci
  let [pfx, x] = [strcharpart(xts, 0, 1), strcharpart(xts, 1)]
  let [a,r] = g:xtref.markers
  if pfx !=# a && pfx !=# r
    echoe "Unsupported xtref format"
    return xts
  endif
  "" ALT:PERF:(native)
  " let hexts = substitute(x, '.', '\=printf("%02x",and(char2nr(submatch(0)),0xff))', 'g')
  " return pfx . strftime('%Y-%m-%d=%H:%M:%S%z', str2nr(hexts, 16))
  return pfx . systemlist('r.vim-xtref -nf '.a:fmt.' -- '.xts)[0]
endf

"" NOTE: cycle loop :: any => braille | braille => iso8601
fun! xtref#to_fmt_cycle(fmt, xloci)
  let fmt = (a:xloci[0] =~# '\v'.s:r_braille) ? a:fmt : 'braille'
  " echom fmt
  return xtref#to_fmt(fmt, a:xloci)
endf

function! xtref#call_at(cwd, fn, ...)
  let l:old = getcwd()
  try
    exe 'lcd '.fnameescape(a:cwd)
  catch
    echom 'Failed to change directory to: '.a:cwd
    return
  finally
    let _ = call(a:fn, a:000)
    if getcwd() !=# l:old
      try| exe 'lcd '.fnameescape(l:old) |catch|endt
    endif
    if v:shell_error
      echoe join(_, '\n')
      return []
    en
  endtry
  return _
endfunction

fun! xtref#ctags(root, ...)
  if !executable('ctags')| echoerr "Not found in PATH: ctags(1)" | return |en
  let dst = shellescape(get(a:, 1, g:xtref.tagfile))
  let _ = join(xtref#call_at(a:root, 'systemlist', 'r.vim-xtref -tr -- -o '.dst), '\n')
  echom "Done: gen xtref tags for ". a:root
endf

fun! xtref#syntax()
  hi! xtrefAnchor ctermfg=24 guifg=#005f87
  call matchadd('xtrefAnchor', '\v'. g:xtref.r_anchor, -1)

  hi! xtrefRefer ctermfg=35 guifg=#00af5f
  call matchadd('xtrefRefer', '\v'. g:xtref.r_refer, -1)
endf


call xtref#syntax()
augroup Xtref
  autocmd!
  au WinEnter * call xtref#syntax()
augroup END


" NOTE: use "xts<C-v><Space>" to insert "xts" literally
iabbrev <expr> !xts! xtref#new()

" OBSOL: <LocalLeader><F2>
nnoremap [Xtref]u :<C-u>XtrefAura<CR>
command! -bar -range -nargs=0  XtrefAura  call xtref#ctags(g:xtref.aura)

" OBSOL: <LocalLeader><F1>
nnoremap [Xtref]c :<C-u>XtrefCwd<CR>
command! -bar -range -nargs=0  XtrefCwd
  \ if $HOME !~# '^'.getcwd()|call xtref#ctags('.')
  \ |else|echoerr "Prevented gen tags in $HOME or below"|en


" NOTE: search tags in *aura*, same folder as current file, and in all parent dirs of CWD
" THINK: hide tags inside .git = systemlist('git rev-parse --git-dir')[0].'/tags' ⌇Gg-nu
" HACK:(tags;/): search file in parent dirs, stop when '/' is reached (OR: use '~') ⌇}p-nu
"   https://stackoverflow.com/questions/5017500/vim-difficulty-setting-up-ctags-source-in-subdirectories-dont-see-tags-file-i
" MAYBE: exe 'set tags^='. g:xtref.aura.'/**/'.g:xtref.tagfile
exe 'set tags^='. g:xtref.aura.'/'.g:xtref.tagfile
exe 'set tags^='. g:xtref.tagfile.';/'
exe 'set tags^='. './'.g:xtref.tagfile.';'


"" NOTE: jump anchor from referal under cursor, and vice versa
" BUG:(TEMP:sil): paused prompt on each :tag
"   => always prints name of file it opens on tag jump
nnoremap g]  :sil exe v:count1."tag" xtref#invert(xtref#get(0))<CR>
xnoremap g]  :<C-u>sil exe v:count1."tag" xtref#invert(xtref#get(1))<CR>
nnoremap z]  :exe "tsel" xtref#invert(xtref#get(0))<CR>
xnoremap z]  :<C-u>exe "tsel" xtref#invert(xtref#get(1))<CR>
 noremap g[  :<C-u><C-r>=v:count1<CR>tnext<CR>
 noremap <C-]>  :<C-u>tags<CR>


"" NOTE: jump to next anchor/referal
noremap <silent>  [x  :<C-u>let @/='\v'.g:xtref.r_anchor<CR>n
noremap <silent>  ]x  :<C-u>let @/='\v'.g:xtref.r_refer<CR>n


nnoremap <Plug>(xtref-new-insert) i<C-r>=xtref#new()<CR><Esc>

nnoremap <Plug>(xtref-new-append) $"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
xnoremap <Plug>(xtref-new-append) "=xtref#new()<CR>p

" FIXME: skip initial commentstring and insert "[_]" directly before actual text
" BAD: when converting URL into task -- we will have two trailing xtrefs
nnoremap <Plug>(xtref-task-convert) 0wi[_]<Space><Esc>$"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
nnoremap <Plug>(xtref-task-insert) i[_]<Space><Esc>
" FIXME: smart commentstring parsing -- allow "//" and "/*"
" FIXME: allow inside multiline block comment /* ... */ -- regex w/o leading commentstring
nnoremap <Plug>(xtref-task-new) :call setline('.', substitute(getline('.'), '\v(['. &commentstring[0] .']+\s*)(\[[_X]\]\s*)?', '\1[_] ', ''))<CR>
nnoremap <Plug>(xtref-task-done) :call setline('.', substitute(getline('.'), '\V[_]\s\?', xtref#new().' [X] ', ''))<CR><Plug>(xtref-yank)

nnoremap <Plug>(xtref-yank-anchor) :<C-u>call xtref#copy(g:xtref.anchor_pfx.xtref#strip(xtref#get(0)))<CR>
xnoremap <Plug>(xtref-yank-anchor) :<C-u>call xtref#copy(g:xtref.anchor_pfx.xtref#strip(xtref#get(1)))<CR>
nnoremap <Plug>(xtref-yank-refer)  :<C-u>call xtref#copy(g:xtref.refer_pfx.xtref#strip(xtref#get(0)))<CR>
xnoremap <Plug>(xtref-yank-refer)  :<C-u>call xtref#copy(g:xtref.refer_pfx.xtref#strip(xtref#get(1)))<CR>

" [_] CHECK: limit #get() area by visual selection for bounded replace
nnoremap <Plug>(xtref-delete) :<C-u>call xtref#replace(0,'')<CR>
xnoremap <Plug>(xtref-delete) :<C-u>call xtref#replace(1,'')<CR>

nnoremap <Plug>(xtref-replace-date) :<C-u>call xtref#replace(0,xtref#to_fmt_cycle('iso',xtref#get(0)))<CR>
xnoremap <Plug>(xtref-replace-date) :<C-u>call xtref#replace(1,xtref#to_fmt_cycle('iso',xtref#get(1)))<CR>

" MAYBE:([Xtref]r): upgrade xtref marker format one-by-one instead of all at once
nnoremap <Plug>(xtref-refresh) :<C-u>call xtref#replace(0,xtref#new())<CR>
xnoremap <Plug>(xtref-refresh) :<C-u>call xtref#replace(1,xtref#new())<CR>

" THINK:FIXME: any "yy" op in vim must modify all {anchor => referer}
"   <= because using <\ x t> on each copied line is too tedious when creating
"   cross-refs for tasks and mentionings
nnoremap <Plug>(xtref-toggle) :<C-u>call xtref#replace(0,xtref#invert(xtref#get(0)))<CR>
xnoremap <Plug>(xtref-toggle) :<C-u>call xtref#replace(1,xtref#invert(xtref#get(1)))<CR>


" OBSOL:  <LocalLeader>...
map <silent> [Xtref]<Backspace> <Plug>(xtref-delete)
map <silent> [Xtref]<Delete> <Plug>(xtref-delete)

map <silent> [Xtref]a <Plug>(xtref-new-append)
map <silent> [Xtref]i <Plug>(xtref-new-insert)
map <silent> [Xtref]d <Plug>(xtref-replace-date)
map <silent> [Xtref]r <Plug>(xtref-refresh)
map <silent> [Xtref]t <Plug>(xtref-toggle)
map <silent> [Xtref]y <Plug>(xtref-yank-refer)
map <silent> [Xtref]Y <Plug>(xtref-yank-anchor)

" BAD: better use unified keybindings for tasks in nou.vim and xtref
"   i.e. always confusing <,.> and <\x>
map <silent> [Xtref]<Space> <Plug>(xtref-task-new)
map <silent> [Xtref]_ <Plug>(xtref-task-insert)
map <silent> [Xtref]x <Plug>(xtref-task-convert)
map <silent> [Xtref]X <Plug>(xtref-task-done)


" HACK: new leader
map <silent>  [Frame]x  [Xtref]
noremap <silent>  [Xtref] <Nop>
