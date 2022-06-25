" ⌇!%:nu
" SPDX-FileCopyrightText: 2020 Dmytro Kolomoiets <amerlyq@gmail.com>
" SPDX-License-Identifier: GPL-3.0-only
" SPDX-PackageName: vim-xtref
" SPDX-PackageSummary: timestamp-based cross-refs manipulation and tagging
"   = xtref = cross(X)-time(T)-references
if &cp||exists('g:loaded_xtref')|finish|else|let g:loaded_xtref=1|endif

let g:xtref = {}
" MAYBE: if list -- use first existing dir [/x, /aura, /data/aura, /home/user/aura]
" [_] FIXME: use /@
let g:xtref.aura = "/@/aura"   " main dir of your global knowledge base
let g:xtref.tagfile = 'xtref.tags' " separate DB for xrefs to prevent
" $VPLUGS = temp store *.tags for newly created/edited files
let g:xtref.lazytagdir = "/@/xdg_cache/nvim"

" ALT: ⌇ => ¶ .like. https://www.yoctoproject.org/docs/3.1.1/brief-yoctoprojectqs/brief-yoctoprojectqs.html
" OR:USE: '⌇' = "\u2307" = [\u2307]
let g:xtref.anchor_pfx = '⌇'
let g:xtref.refer_pfx = '※'
let g:xtref.task_pfx = '['
let g:xtref.step_pfx = '^'
let g:xtref.event_pfx = '<'
let g:xtref.markers = [g:xtref.anchor_pfx, g:xtref.refer_pfx]
let g:xtref.prefixes = g:xtref.markers + [g:xtref.task_pfx, g:xtref.step_pfx]

" TODO: support for nanoseconds tail
" ALT:(queue): $ r.vim-xtref -pp $ ALT:(generic): '\S{3,20}\ze\s?'
let s:r_z85 = '[-0-9a-zA-Z.:+=^!/*?&<>()\[\]{}@%$#]{5}'
let s:r_brchr = '\u2800-\u28FF'
let s:r_bryes = '['.s:r_brchr.']'
let s:r_brnot = '[^'.s:r_brchr.']'
let s:r_braille = s:r_bryes . '{2,4}'
let g:xtref.r_addr = '('. s:r_z85 .'|'. s:r_braille .')'
" IDEA: allow xtref free format in brackets ※[so me] instead of time-format
"  ALT: use completely different braces
let g:xtref.r_anchor = g:xtref.anchor_pfx . g:xtref.r_addr
let g:xtref.r_refer = g:xtref.refer_pfx . g:xtref.r_addr


" NOTE: xref artifact ※unReK
digraph xa 8967  " ⌇
digraph xr 8251  " ※

fun! xtref#vsel()
  let [lbeg, cbeg] = getpos("'<")[1:2]
  let [lend, cend] = getpos("'>")[1:2]
  let lines = getline(lbeg, lend)
  if len(lines) == 0
      return ''
  endif
  " OLD:BUG:(unicode): let lines[-1] = lines[-1][: cend - (&selection == 'inclusive' ? 1 : 2)]
  "   FIXME: ±1 must be proportional to size of last char
  " INFO: cend is position _before_ right edge (w/o last unicode char)
  "   -- you must extend it by charlen (of last unicode char in selection)
  let uc_len = strchars(lines[-1][:cend - 2]) + 1
  let lines[-1] = strcharpart(lines[-1], 0, uc_len)
  let lines[0] = lines[0][cbeg - 1:]
  return join(lines, "\n")
endf

fun! xtref#copy(xtref, ...)
  " RUL(don't add leading space): I often add space myself
  " [_] ENH: if a:1 is array == surround xtref by valus
  call setreg(get(a:,2,'+'), get(a:,1,'') . a:xtref, 'c')
endf

fun! xtref#new(...)
  "" DEPRECATED:(z85):
  " let xts = printf('%08x', call('strftime', ['%s'] + a:000))
  " let xts = systemlist('xxd -p -r | basenc --z85 | rev', xts)[0]
  "" ALT:PERF: systemlist('r.vim-xtref '.get(a:,1))[0]
  let xts = substitute(printf('%08x', strftime('%s')), '..', '\=nr2char("0x28".submatch(0))', 'g')
  " MAYBE:REMOVE:BET:USE explicit <Plug>(xtref-yank) -- lib function must not do side-effects
  call xtref#copy(g:xtref.refer_pfx . xts)
  return get(a:,1,g:xtref.anchor_pfx) . xts . get(a:,2,'')
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
  if a:visual < 0
    return [xtref#vsel(), 0]
  elseif a:visual
    let [l,c] = [xtref#vsel(), 0]
  else
    let [l,c] = [getline('.'), col('.')-1]
  endif

  if !a:visual && match(strcharpart(l[c:],0,1), s:r_bryes) == 0
    let lchars = reverse(split(l[:c-1], '\zs'))
    let b = match(lchars, s:r_brnot)
    " NOTE: always include prefix to jump by tag "g]"
    if index(g:xtref.prefixes, lchars[b]) >= 0| let b = b + 1 |en
    let e = match(split(l[c:], '\zs'), s:r_brnot)
    let x = strcharpart(l, len(lchars)-b, b+e)
    return [x, 0]
    " return [x, strlen(join(lchars[:b],''))]
    " return [x, -strlen(strcharpart(l, len(lchars)-b))]
  end

  "" FIXME: enforce suffix for "surrounding" markers "[<braille>]"
  let pfxs = g:xtref.prefixes
  let b = xtref#lseek(l, pfxs, c)
  let e = xtref#rseek(l, pfxs, c)
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

  " NOTE: get only first xtref from xtref-train
  let e = xtref#rseek(l, pfxs, b+1)
  if e<0 | let e = len(l) |en

  " NOTE: space is an absolute separator between xtrefs
  "   BUT:THINK: for tasks -- use ALL content inside [...] as "x"
  " MAYBE:BET?(simplify): x=l=sub('\s.*','') && e=len(l)
  let s = match(l, '\s', b)
  if s>=0
    " DEBUG: echo strpart(l, b, s-b) .'|'. strpart(l, s+1)
    " FIXED: allow iso8601 date with usual space separator
    if strpart(l, b, s-b) =~ '20\d\d-\d\d-\d\d$'
       \ && strpart(l, s+1) =~ '^\d\d:\d\d:\d\d'
    let s = match(l, '\s', s+1)
  en|en
  let len = (s>=0 && s<e) ? s-b : e-b

  " NOTE: strip trailing decorative alias for braille-based xtrefs_4+
  "   e.g. ※⡟⡵⠤⢓/comment  MAYBE: hi! this "comment" the same as anchor
  let x = strpart(l, b, len)
  let x = substitute(x, '\v^.'. s:r_braille .'\zs.*', '', '')

  " DEBUG: echom join([l, b, len, b-c, x], ' ')
  return [x, b-c]
endf

" [_] BUG: \xd calls twice #get()
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
  if index(g:xtref.prefixes, pfx) < 0 | return expand('<cword>') | en
  return (pfx ==# a ? r : a) . strcharpart(x, 1)  " fnameescape()
endf

" [_] TODO: allow converting any unprefixed {date <-> braille}
fun! xtref#cvt(fmt, xts)
  if a:xts =~# '\v^'. s:r_bryes .'{2}$'
    return systemlist('just xts cvt '.shellescape(a:xts).' xts2 date')[0]
  elseif a:xts =~# '^20\d\d-\d\d-\d\d$'
    return systemlist('just xts cvt '.shellescape(a:xts).' date xts2')[0]
  end
  "" ALT:PERF:(native)
  " let hexts = substitute(x, '.', '\=printf("%02x",and(char2nr(submatch(0)),0xff))', 'g')
  " return strftime('%Y-%m-%d=%H:%M:%S%z', str2nr(hexts, 16))
  return systemlist('r.vim-xtref -nf '.a:fmt.' -- '.shellescape(a:xts))[0]
endf

"" NICE: use "r.vim-xtref" as SPOT
" VIZ:(fmt): braille hex dt date utc unix z85 z85r
fun! xtref#to_fmt(fmt, xloci)
  let [xts, off] = a:xloci
  let [pfx, x] = [strcharpart(xts, 0, 1), strcharpart(xts, 1)]
  let [a,r] = g:xtref.markers

  " [_] THINK: remove this switch-case as whole and depend on error from "r.vim-xtref"
  if xts =~# '\v^'. s:r_bryes || xts =~# '^20\d\d'
    return xtref#cvt(a:fmt, xts)
  elseif pfx ==# '['
    " NOTE: task-ts conversion :: [⡞⣾⠂⢐] <=> [20XX-...]
    let [x, sfx] = (stridx(x, ']') < 0) ? [x, ''] : split(x, '\ze\]')
    return pfx . xtref#cvt(a:fmt, x) . sfx
  elseif pfx ==# a || pfx ==# r  " || pfx=='^'
    return pfx . xtref#cvt(a:fmt, xts)
  endif

  echoe "Unsupported xtref format"
  return xts
endf

"" NOTE: cycle loop :: any => braille | braille => iso8601
fun! xtref#to_fmt_cycle(fmt, xloci)
  " echom a:xloci[0]
  let fmt = (a:xloci[0] =~# '\v'.s:r_bryes) ? a:fmt : 'braille'
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


" DEV: update tags from added buffers ※⡟⢋⡤⣒
" ALSO:(async): auto-update tags on file close
fun! xtref#ctags(root, ...)
  if !executable('ctags')| echoerr "Not found in PATH: ctags(1)" | return |en
  let dstdir = get(a:, 2, a:root)
  let dst = shellescape(dstdir.'/'.g:xtref.tagfile)
  " let dst = shellescape(get(a:, 1, g:xtref.tagfile))

  " NOTE: append tags only from file paths passed as arg (e.g. ~BufClose~)
  "   OR from all opened buffers (manually)
  let bufs = get(a:, 1, [])
  if type(bufs) == type(1) && bufs == 1
    if !isdirectory(dstdir)| call mkdir(dstdir, 'p', 0700) |en
    let bufs = filter(map(copy(getbufinfo()), 'v:val.name'), 'len(v:val)')
  end

  " let cmd = 'r.vim-xtref -t -- -o '.dst
  let cmd = '/@/airy/vim/ctl/xtref -t -- -o '.dst
  if dstdir != a:root
    let cmd .= ' --tag-relative=never'
  end

  if !len(bufs)
    let cmd .= ' --recurse'
  elseif type(bufs) == type([])
    " THINK:CHG: append to separate overlay
    "   let tmp = g:xtref.lazytagdir.'/'.g:xtref.tagfile
    "   << NEED: delete this overlay each time you regen proper Aura or Repo tags
    "" NICE:(-a): ¦ After creating or appending to the tag file, it is sorted by the tag name, removing identical tag lines.
    "   ALT:(BufWritePost): append instead of overwrite, and then dedupl by awk
    "   FAIL: when lines inserted/deleted -- positions of xtrefs below the edit will move,
    "     and old stale ones won't be auto-removed
    "   FIXME: filter-out all xtrefs (with passed filepaths) before appending
    "     [_] FUTURE: remove stale xtrefs from lazydir
    "     [_] FUTURE: remove deleted files from lazydir
    let cmd .= ' --append '. join(map(bufs, 'shellescape(v:val)'), ' ')
    echom cmd
  elseif type(bufs) == type('') && bufs[0] == '.'
    let cmd .= ' --recurse '. join(map(split(bufs, ','), '"--map-xtref=".v:val'), ' ')
  end

  " FIXME: use async job
  let _ = join(xtref#call_at(a:root, 'systemlist', cmd), '\n')
  echom 'DONE:('. a:root .') -> '. dst
endf


" BAD: original text italic,bold,underline will affect xtrefs ⌇⡟⡵⠪⡆
" FAIL: "NONE" does not reset style when overlaying on top of regular hi
"   [⡟⡵⠱⣘] TRY: add hi suppression at least into .nou syntax
"   [_] MAYBE: skip "matchadd(...)" if "syn match" already exists
"     TRY:USE: getmatches() OR empty(synIDattr(hlID('xtrefAnchor'), 'name'))
fun! xtref#syntax()
  hi def xtrefAnchor ctermfg=24 guifg=#005f87 cterm=NONE gui=NONE
  call matchadd('xtrefAnchor', '\v'. g:xtref.r_anchor, -1)

  hi def xtrefRefer ctermfg=1 guifg=#00af5f cterm=NONE gui=NONE
  call matchadd('xtrefRefer', '\v'. g:xtref.r_refer, -1)

  hi def xtrefReferPfx ctermfg=41 guifg=#3fcf5f cterm=NONE gui=NONE
  call matchadd('xtrefReferPfx', '\v'. g:xtref.refer_pfx, -1)
endf


call xtref#syntax()
augroup Xtref
  autocmd!
  au WinEnter * call xtref#syntax()

  " WKRND: wront encoding detection
  " exe 'au! BufRead,BufNewFile '. g:xtref.tagfile .' edit ++enc=utf8'

  "" [_] ENH: parse !ctags only in diff from last write
  " NICE: incremental update -- i.e. append tags from all changed files
  " BUG: called twice on first write
  au BufWritePost * sil call xtref#ctags(g:xtref.lazytagdir,
    \ [expand('<afile>:p',1)])

  " NOTE: only modified buffers
  " OR: au BufDelete *
  " OR :echo getbufinfo({'bufmodified': 1})->map({ _, b -> b.bufnr })->join(',')
  " BUG: always shows "[unite] - mrus" as modified
  " FAIL: on BufUnload all files are already saved
  "   NEED: detect somehow if file was modified at least once from the moment
  "   of opening vim instance -- and reset this var after writing tags
  " au BufUnload * if index(map(getbufinfo({'bufmodified':1}), 'v:val.bufnr'), '<bufnr>') > -1
  "   \| call xtref#ctags(g:xtref.lazytagdir, ['<afile>']) |en
augroup END


" NOTE: use "xts<C-v><Space>" to insert "xts" literally
iabbrev <expr> !xts! xtref#new()

"" DISABLED: prevent overwriting long lazytagdir by short *.nou-only
" nnoremap [Xtref]U :<C-u>XtrefNou<CR>
" command! -bar -range -nargs=0  XtrefNou  call xtref#ctags(g:xtref.aura, '.nou,.task')

nnoremap [Xtref]u :<C-u>XtrefOpened<CR>
command! -bar -range -nargs=0  XtrefOpened
  \ call xtref#ctags(g:xtref.lazytagdir, 1)

" DEPS: https://github.com/airblade/vim-rooter
nnoremap [Xtref]<C-u> :<C-u>XtrefRepo<CR>
command! -bar -range -nargs=0  XtrefRepo
  \ call xtref#ctags(FindRootDirectory())

" FIXME: prevent in /@ and many other system/network locations
nnoremap [Xtref]<A-u> :<C-u>XtrefCwd<CR>
command! -bar -range -nargs=0  XtrefCwd
  \ if $HOME !~# '^'.getcwd()|call xtref#ctags('.')
  \ |else|echoerr "Prevented gen tags in $HOME or below"|en

"" HACK: use same g:lazytagdir for initial @/aura and then for --append()
" OBSOL: <LocalLeader><F2>
nnoremap [Xtref]<A-S-u> :<C-u>XtrefAura<CR>
command! -bar -range -nargs=0  XtrefAura
  \ call xtref#ctags(g:xtref.aura, [], g:xtref.lazytagdir)

" NOTE: search tags in *aura*, same folder as current file, and in all parent dirs of CWD ※}p-nu
" MAYBE: exe 'set tags^='. g:xtref.aura.'/**/'.g:xtref.tagfile
exe 'set tags^='. g:xtref.tagfile.';/'
exe 'set tags^='. g:xtref.lazytagdir.'/'.g:xtref.tagfile
exe 'set tags^='. './'.g:xtref.tagfile.';'


fun! xtref#py_jump(...)
py3 << EOF
import just.flower.xts.parse as M
ctx = vim.current
if m := M.find_near(ctx.line, ctx.window.cursor[1]):
  pfx = "※" if m.group(0)[0] == "⌇" else "⌇"
  vn = vim.eval("v:count")
  cmd = vn + "tag" if vn != "0" else "tjump"
  vim.command(cmd + " " + pfx + m.group(1))
EOF
endf
nnoremap <Plug>(xtref-jump)  :<C-u>call xtref#py_jump()<CR>

map  g]        <Plug>(xtref-jump)
map  g<Space>  <Plug>(xtref-jump)


"" NOTE: jump anchor from referal under cursor, and vice versa
" BUG:(TEMP:sil): paused prompt on each :tag
"   => always prints name of file it opens on tag jump
" [_] TRY: also overload <gf> to open xtref under cursor as if it was "file"
" BAD:NEED:(sil): suppress "search hit bottom" message and jump immediately
"   ::: FIXED: [⡡⡂⢡⡾] #xtref FIX pause on jump ::: :set shortmess+=s
" [_] FIXME: always use "tag" if over xtref SEP function
" nnoremap <silent>  g]  :exe (v:count?v:count."tag":"tjump") xtref#invert(xtref#get(0))<CR>
xnoremap <silent>  g]  :<C-u>exe (v:count?v:count."tag":"tjump") xtref#invert(xtref#get(1))<CR>
 noremap <silent>  g[  :<C-u><C-r>=v:count1<CR>tag<CR>

nnoremap <silent>  z]  :exe "tsel" xtref#invert(xtref#get(0))<CR>
xnoremap <silent>  z]  :<C-u>exe "tsel" xtref#invert(xtref#get(1))<CR>
 noremap           z[  :<C-u><C-r>=v:count1<CR>tnext<CR>

 noremap <C-]>  :<C-u>tags<CR>


"" NOTE: jump to next anchor/referal
noremap <silent>  [x  :<C-u>let @/='\v'.g:xtref.r_anchor<CR>n
noremap <silent>  ]x  :<C-u>let @/='\v'.g:xtref.r_refer<CR>n

"" FAIL: conflicts with [Xtref] TRY:USE: unicode brakets instead of Ascii for [Xtref] .im. alias
" noremap <silent>  [X  :<C-u>let @/='\v'.g:xtref.r_anchor<CR>N
" noremap <silent>  ]X  :<C-u>let @/='\v'.g:xtref.r_refer<CR>N


"" WTF:(<Plug>(xtref-yank)): does not exists ?
nnoremap <Plug>(xtref-new-insert) i<C-r>=xtref#new("")<CR><Esc>
nnoremap <Plug>(xtref-new-prepend) ^"=xtref#new()." "<CR>P<Plug>(xtref-yank)

nnoremap <Plug>(xtref-new-append) $"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
xnoremap <Plug>(xtref-new-append) "=xtref#new()<CR>p
nnoremap <Plug>(xtref-new-postpone) $"=" ".xtref#new('<','>')<CR>p

" FIXME: skip initial commentstring and insert "[_]" directly before actual text
" BAD: when converting URL into task -- we will have two trailing xtrefs
nnoremap <Plug>(xtref-task-convert) 0wi[_]<Space><Esc>$"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
nnoremap <Plug>(xtref-task-insert) i[_]<Space><Esc>
" FIXME: smart commentstring parsing -- allow "//" and "/*"
" FIXME: allow inside multiline block comment /* ... */ -- regex w/o leading commentstring
nnoremap <Plug>(xtref-task-new) :call setline('.', substitute(getline('.'), '\v(['. &commentstring[0] .']+\s+)(\[[_X]\]\s*)?', '\1[_] ', ''))<CR>
nnoremap <Plug>(xtref-task-done) :call setline('.', substitute(getline('.'), '\V[_]\s\?', xtref#new().' [X] ', ''))<CR><Plug>(xtref-yank)

nnoremap <Plug>(xtref-yank-anchor) :<C-u>call xtref#copy(g:xtref.anchor_pfx.xtref#strip(xtref#get(0)),repeat(' ',v:count))<CR>
xnoremap <Plug>(xtref-yank-anchor) :<C-u>call xtref#copy(g:xtref.anchor_pfx.xtref#strip(xtref#get(1)),repeat(' ',v:count))<CR>
nnoremap <Plug>(xtref-yank-refer)  :<C-u>call xtref#copy(g:xtref.refer_pfx.xtref#strip(xtref#get(0)),repeat(' ',v:count))<CR>
xnoremap <Plug>(xtref-yank-refer)  :<C-u>call xtref#copy(g:xtref.refer_pfx.xtref#strip(xtref#get(1)),repeat(' ',v:count))<CR>

" [_] CHECK: limit #get() area by visual selection for bounded replace
nnoremap <Plug>(xtref-delete) :<C-u>call xtref#replace(0,'')<CR>
xnoremap <Plug>(xtref-delete) :<C-u>call xtref#replace(1,'')<CR>

" [_] TODO: allow plain timestamp (with optional spaced timezone like git show --raw) as xtref
"   ENH: preview iso date in statusline or in NEW floating window

""
py3 import vim

" FUTURE:ENH: "append" to already existing postopone chain <A|B|C|...>
fun! xtref#py_postpone(...)
py3 << EOF
import just.flower.xts.cvt as C
vim.current.line += " <" + C.date_to_xts2() + ">"
EOF
endf

nnoremap <Plug>(xtref-new-postpone-day) :<C-u>call xtref#py_postpone()<CR>


fun! xtref#pytest_cvt()
py3 << EOF
import just.flower.xts.parse as M
ctx = vim.current
chg = M.replace_near(ctx.line, ctx.window.cursor[1], form='next')
if chg != ctx.line:
  ctx.line = chg
EOF
endf

nnoremap <Plug>(xtref-replace-datetime) :<C-u>call xtref#pytest_cvt()<CR>
" nnoremap <Plug>(xtref-replace-datetime) :<C-u>call xtref#replace(0,xtref#to_fmt_cycle('date',xtref#get(0)))<CR>

" FIXED:(-1): use exact visual selection (to allow spaces in ISO date, etc.)
"   instead of auto-locating xtref in selected area
xnoremap <Plug>(xtref-replace-datetime) :<C-u>call xtref#replace(-1,xtref#to_fmt_cycle('date',xtref#get(-1)))<CR>

" MAYBE:([Xtref]r): upgrade xtref marker format one-by-one instead of all at once
nnoremap <Plug>(xtref-refresh) :<C-u>call xtref#replace(0,xtref#new())<CR>
xnoremap <Plug>(xtref-refresh) :<C-u>call xtref#replace(1,xtref#new())<CR>

" RENAME: [t]oggle => [c]onve[r]t => s[w]itch => inve[r]t
" THINK:FIXME: any "yy" op in vim must modify all {anchor => referer}
"   <= because using <\ x t> on each copied line is too tedious when creating
"   cross-refs for tasks and mentionings
nnoremap <Plug>(xtref-invert) :<C-u>call xtref#replace(0,xtref#invert(xtref#get(0)))<CR>
xnoremap <Plug>(xtref-invert) :<C-u>call xtref#replace(1,xtref#invert(xtref#get(1)))<CR>


" OBSOL:  <LocalLeader>...
map <silent> [Xtref]<Backspace> <Plug>(xtref-delete)
map <silent> [Xtref]<Delete> <Plug>(xtref-delete)

map <silent> [Xtref]a <Plug>(xtref-new-append)
map <silent> [Xtref]A <Plug>(xtref-new-postpone-day)
map <silent> [Xtref]i <Plug>(xtref-new-insert)
map <silent> [Xtref]I <Plug>(xtref-new-prepend)
map <silent> [Xtref]> <Plug>(xtref-new-postpone)
map <silent> [Xtref]d <Plug>(xtref-replace-datetime)
map <silent> [Xtref]r <Plug>(xtref-invert)
map <silent> [Xtref]R <Plug>(xtref-refresh)
map <silent> [Xtref]t <Plug>(xtref-replace-datetime)
map <silent> [Xtref]y  <Plug>(xtref-yank-refer)
map <silent> [Xtref]Y 1<Plug>(xtref-yank-refer)
map <silent> [Xtref]gy <Plug>(xtref-yank-anchor)

" BAD: better use unified keybindings for tasks in nou.vim and xtref
"   i.e. always confusing <,.> and <\x>
map <silent> [Xtref]<Space> <Plug>(xtref-task-new)
map <silent> [Xtref]_ <Plug>(xtref-task-insert)
map <silent> [Xtref]x <Plug>(xtref-task-convert)
map <silent> [Xtref]X <Plug>(xtref-task-done)


" HACK: new leader
map <silent>  \x  [Xtref]
noremap <silent>  [Xtref] <Nop>
