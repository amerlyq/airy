""" lyrics-ed.vim

fun! lyrics#init()
  if !exists('$TMPDIR')
    let $TMPDIR = fnamemodify(system('mktemp --dry-run --tmpdir'), ':h')
  endif
  let dir = $TMPDIR.'/lyrics/'
  call mkdir(dir, 'p', 0700)

  let g:buf = {'keys': ['o', 'p', 't']}
  for k in g:buf.keys | let g:buf[k] = {'path': dir.k} | endfor
endf

if !exists('g:buf') | call lyrics#init() | endif

fun! s:gargs(...)
  let b = get(a:, 1, a:firstline)
  let e = get(a:, 2, a:lastline)
  return [b, e]
endf

fun! lyrics#lsort(bang, ...) range
  let [b, e] = call('s:gargs', a:000)
  let k = (a:bang ?'': 'r')
  " tabnew
  " setl winfixwidth winfixheight buftype=nofile bufhidden=wipe nobuflisted
  " call lyrics#cfg()
  sil exe b.','.e."!awk '{print length,$0}'|sort -ns".k."|cut -d' ' -f2-"
endf


fun! lyrics#cfg()
  setl ts=2 sw=2 sts=2 fdl=99
  setl nowrap virtualedit=all cursorcolumn
  setl number norelativenumber
  setl scrollbind
  return winnr()
endf


fun! lyrics#load()
  sil only
  exe   'edit '.g:buf.o.path | let g:buf.o.win = lyrics#cfg()
  exe 'vsplit '.g:buf.p.path | let g:buf.p.win = lyrics#cfg()
  exe 'vsplit '.g:buf.t.path | let g:buf.t.win = lyrics#cfg()
  wincmd =
  exe g:buf.o.win . 'wincmd w'
endf


fun! lyrics#analyze(...)
  let [b, e] = call('s:gargs', a:000)
  " WARNING: you need to open buffers beforehand or getbufline() will be wrong!
  " ALT: fileread() but then you can't join 'nofile'/changed buffers correctly!
  for B in map(copy(g:buf.keys), 'g:buf[v:val]')
    let B.lns = getbufline(bufname('^'.B.path.'$'), b, e)
    let B.max = max(map(copy(B.lns), 'strdisplaywidth(v:val)'))

    let m = 0
    let B.bks = []
    while m >= 0
      let m = match(B.lns, '\v%(^[ \t\u3000]*$)@!', m)
      if m < 0 | break | endif
      let B.bks += [[m]]
      let m = match(B.lns, '\v^[ \t\u3000]*$', m)
      if m < 0
        let B.bks[-1] += [len(B.lns) - 1]
      else
        let B.bks[-1] += [m - 1]
      endif
    endwhile
  endfor
endf


" For old vims to print aligned wide-byte:
" SEE https://groups.google.com/forum/#!topic/vim_dev/vBNoI0f1GU4
fun! s:join_line(i)
  return join(map(copy(g:buf.keys), "printf(
        \ '%-'.g:buf[v:val].max.'S', get(g:buf[v:val].lns, a:i, ''))"), '|')
endf

fun! lyrics#join(...) range
  let [b, e] = call('s:gargs', a:000)
  call lyrics#analyze(b, e)
  let N = max(map(copy(g:buf.keys), 'len(g:buf[v:val].lns)'))
  tabnew | enew
  setl buftype=nofile
  call append(0, map(range(N), 's:join_line(v:val)'))
  TrailingStrip
  norm! gg0
endf


fun! s:strip(s)
  return substitute(a:s, '\v[ \t\u3000]+$', '', '')
endf

fun! lyrics#split(...) range
  let [b, e] = call('s:gargs', a:000)
  let lns = filter(map(getline(b, e),
        \ 'split(v:val." ", "|")'), 'len(v:val)>=3')
  if empty(lns) || len(lns[0])<3 | return | endif

  for i in range(3)
    let f = g:buf[g:buf.keys[i]].path
    call writefile(map(copy(lns), 's:strip(v:val['.i.'])'), f)
  endfor
  tabnew | call lyrics#load()
endf


fun! lyrics#shuffle(bang, ...) range
  call call('lyrics#analyze', call('s:gargs', a:000))

  let bks = g:buf[g:buf.keys[0]].bks
  for k in g:buf.keys
    if len(g:buf[k].bks) != len(bks)
      echom "Err: unmatched number of blocks / verses"
      return
    endif
  endfor

  let lines = []
  if a:bang
    let N = min(map(copy(g:buf.keys), 'len(g:buf[v:val].lns)'))
    for i in range(N)
      let B = map(copy(g:buf.keys), 'g:buf[v:val].lns[i]')
      if empty(filter(B, '!empty(v:val)')) | let B = [''] | endif
      let lines += B + ['']
    endfor
  else
    for i in range(len(bks))
      for k in g:buf.keys
        let [b, e] = g:buf[k].bks[i]
        let lines += g:buf[k].lns[b : e] + ['']
      endfor
      let lines += ['']
    endfor
  endif

  tabnew | enew
  setl buftype=nofile
  call append(0, lines)
  TrailingStrip
  norm! gg0
endf
