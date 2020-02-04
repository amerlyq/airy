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

fun! xtref#new(...)
  "" DEPRECATED:(z85):
  " let xts = printf('%08x', call('strftime', ['%s'] + a:000))
  " let xts = systemlist('xxd -p -r | basenc --z85 | rev', xts)[0]
  "" ALT:PERF: systemlist('r.vim-xtref '.get(a:,1))[0]
  let xts = substitute(printf('%x', strftime('%s')), '..', '\=nr2char("0x28".submatch(0))', 'g')
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
  let pfx = strcharpart(t, 0, 1)
  " NOTE: keep regular tags untouched ALT:USE: (pfx==a ? r : pfx==r ? a : pfx)
  if pfx!=#a && pfx!=#r| return expand('<cword>') | en
  return (pfx==a ? r : a) . strcharpart(t, 1)  " fnameescape()
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
" BUG:(TEMP:sil): paused prompt on each :tag
"   => always prints name of file it opens on tag jump
nnoremap g]  :sil exe v:count1."tag" xtref#invert()<CR>
xnoremap g]  :<C-u>sil exe v:count1."tag" xtref#invert(xtref#vsel)<CR>
nnoremap z]  :sil exe "tsel" xtref#invert()<CR>
xnoremap z]  :<C-u>sil exe "tsel" xtref#invert(xtref#vsel)<CR>
 noremap g[  :<C-u><C-r>=v:count1<CR>tnext<CR>


"" NOTE: jump to next anchor/referal
noremap <silent>  [x  :<C-u>let @/='\v'.g:xtref.r_anchor<CR>n
noremap <silent>  ]x  :<C-u>let @/='\v'.g:xtref.r_refer<CR>n


nnoremap <Plug>(xtref-new) $"=" ".xtref#new()<CR>p<Plug>(xtref-yank)
xnoremap <Plug>(xtref-new) "=xtref#new()<CR>p
nnoremap <Plug>(xtref-yank) :<C-u>call setreg('+',xtref#invert(),'c')<CR>
xnoremap <Plug>(xtref-yank) :<C-u>call setreg('+',xtref#invert(xtref#vsel()),'c')<CR>

nmap <silent> <LocalLeader>a <Plug>(xtref-new)
xmap <silent> <LocalLeader>a <Plug>(xtref-new)
nmap <silent> <LocalLeader>A <Plug>(xtref-yank)
xmap <silent> <LocalLeader>A <Plug>(xtref-yank)
