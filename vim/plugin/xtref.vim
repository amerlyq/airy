" ⌇!%:nu
" SPDX-FileCopyrightText: 2020 Dmytro Kolomoiets <amerlyq@gmail.com>
" SPDX-License-Identifier: GPL-3.0-only
" SPDX-PackageName: vim-xtref
" SPDX-PackageSummary: timestamp-based cross-refs manipulation and tagging
"

let g:xtref = {}
let g:xtref.aura = $HOME."/aura"   " main dir of your global knowledge base
let g:xtref.tagfile = 'xtref.tags' " separate DB for xrefs to prevent
let g:xtref.refer_pfx = '※'
let g:xtref.anchor_pfx = '⌇'
let g:xtref.exclude = ['.git', '_build*', 'tags', '*.tags']

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

fun! xtref#new(...)
  let xts = printf('%08x', call('strftime', ['%s'] + a:000))
  let xts = systemlist('xxd -p -r | basenc --z85 | rev', xts)[0]
  call setreg('+', g:xtref.refer_pfx . xts, 'c')
  return g:xtref.anchor_pfx . xts
endf

fun! xtref#invert(...)
  let a = g:xtref.anchor_pfx
  let r = g:xtref.refer_pfx

  " [_] THINK:TODO: jump from anywhere on current line :: auto-traverse it left-right
  "   BAD: regular tags will be always ignored MAYBE: apply only for nou.vim
  if a:0 > 0
    let t = a:1
  else
    " FIXED: expand('<cWORD>') don't support glued train of anchors/referals
    let t = getline('.')
    let lt = substitute(strcharpart(t, 0, col('.')), '^.*\ze['.a.r.']', '', '')
    let rt = substitute(strcharpart(t, col('.')), '['.a.r.'].*', '', '')
    let t = lt . rt
  end
  " NOTE: keep regular tags untouched
  let pfx = strcharpart(t, 0, 1)
  if pfx!=#a && pfx!=#r| return expand('<cword>') | en
  return (pfx==a ? r : a) . strcharpart(t, 1, 5)  " fnameescape()
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
  endtry
  return _
endfunction

fun! xtref#ctags(root, ...)
  if !executable('ctags')| echoerr "Not found in PATH: ctags(1)" | return |en
  let dst = get(a:, 1, g:xtref.tagfile)
  let cmd = "ctags --options=NONE -o ". dst
    \." --recurse --input-encoding=UTF-8 --output-encoding=UTF-8"
    \." --langdef=xtref --map-xtref='(*)'"
    \." --kinddef-xtref=a,anchor,place"
    \." --kinddef-xtref=r,reference,jump"
    \." --regex-xtref='/(". g:xtref.anchor_pfx ."\\S{5,})\\s?/\\1/a/'"
    \." --regex-xtref='/(". g:xtref.refer_pfx ."\\S{5,})\\s?/\\1/r/'"
    \." --languages=xtref --excmd=combine"

  if filereadable('.ignore')| let cmd .=' --exclude=@.ignore' |en
  if filereadable('.gitignore')| let cmd .=' --exclude=@.gitignore' |en
  for g in g:xtref.exclude
    let cmd .= " --exclude=".shellescape(g)
  endfor

  " DEBUG: echom cmd
  let _ = join(xtref#call_at(a:root, 'systemlist', cmd), '\n')
  echom "Done: gen xtref tags for ". a:root
endf

fun! xtref#syntax()
  hi! xtrefAnchor ctermfg=24 guifg=#005f87
  call matchadd('xtrefAnchor', '\v'. g:xtref.anchor_pfx .'\S{5,}\ze\s?', -1)

  hi! xtrefRefer ctermfg=35 guifg=#00af5f
  call matchadd('xtrefRefer', '\v'. g:xtref.refer_pfx .'\S{5,}\ze\s?', -1)
endf


call xtref#syntax()
augroup Xtref
  autocmd!
  au WinEnter * call xtref#syntax()
augroup END


" NOTE: use "xts<C-v><Space>" to insert "xts" literally
iabbrev <expr> !xts! xtref#new()

nnoremap <LocalLeader><F2> :<C-u>XtrefAura<CR>
command! -bar -range -nargs=0  XtrefAura  call xtref#ctags(g:xtref.aura)

nnoremap <LocalLeader><F1> :<C-u>XtrefCwd<CR>
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
noremap g]  :<C-u>exe v:count1."tag" xtref#invert()<CR>
noremap z]  :<C-u>exe "tsel" xtref#invert()<CR>
noremap g[  :<C-u><C-r>=v:count1<CR>tnext<CR>


"" NOTE: jump to next anchor/referal
noremap <silent>  [x  :<C-u>let @/=g:xtref.anchor_pfx<CR>n
noremap <silent>  ]x  :<C-u>let @/=g:xtref.refer_pfx<CR>n


nnoremap <Plug>(xtref-new) $"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
xnoremap <Plug>(xtref-new) "=xtref#new()<CR>p
nnoremap <Plug>(xtref-yank) :<C-u>call setreg('+',xtref#invert(),'c')<CR>
xnoremap <Plug>(xtref-yank) :<C-u>call setreg('+',xtref#invert(xtref#vsel()),'c')<CR>

nmap <silent> <LocalLeader>a <Plug>(xtref-new)
xmap <silent> <LocalLeader>a <Plug>(xtref-new)
nmap <silent> <LocalLeader>A <Plug>(xtref-yank)
xmap <silent> <LocalLeader>A <Plug>(xtref-yank)
