
let g:jupyter_mapkeys = 0

" FIXED:(removed '##'): prevent .py code hi! in my own header '## …' comments
let g:jupyter_cell_separators = ['#%%', '# %%', '# <codecell>']

augroup jupy
" DISABLED: file is re-sourced on each .py buffer, resetting prev exec-on-write
" autocmd!
au! FileType python call BufMap_jupyter_vim()
augroup END

" \\n    noremap  <silent> <Plug>JupyterRunVisual     :<C-u>call <SID>opfunc_run_code(visualmode())<CR>gv
" \\n    nnoremap <buffer><silent><unique>  <LocalLeader>U :JupyterUpdateShell<CR>

fun! s:mapsendcode(k, pfx, ...) abort
  exe 'nnoremap <buffer><silent><unique>  <LocalLeader>'.a:k.' :call jupyter#SendCode("'.a:pfx.'".expand("<cexpr>")."'.get(a:,1,"").'")<CR>'
  exe 'xnoremap <buffer><silent><unique>  <LocalLeader>'.a:k.' "sy:<C-u>call jupyter#SendCode("'.a:pfx.'".getreg("s")."'.get(a:,1,"").'")<CR>'
endf


fun! Jupyter_connected() abort
  return py3eval('"_jupyter_session" in globals() and _jupyter_session.kernel_client.check_connection()')
endfun


fun! Jupyter_connect_buf() abort
  if !Jupyter_connected()
    JupyterConnect
    sleep 200m
  en
  call jupyter#SendCode(InferJupyterPkg())
  JupyterRunFile -niG %:p
endfun


fun! Jupyter_send_pprint(text) abort
  let lines = split(a:text, "\n")
  " for i in range(len(lines))
  "   let lines[i] = substitute(lines[i], '^\s*return\s*', '', '')
  " endfor
  let lines[-1] = substitute(lines[-1], '^\s*return\s*', '', '')
  if len(lines) == 1
    let lines[0] = 'p('.lines[0].')'
  else
    " WARN: only works for black-formatted python
    let idx = stridx(lines[-1], " = ")
    if idx != -1
      " HACK: pprint last assignment
      let lastvar = trim(strpart(lines[-1], 0, idx))
      call add(lines, 'p('.lastvar.')')
    endif
  endif
  let code = join(lines, "\n")
  " OR: call Fn(code)
  return jupyter#SendCode(code)
endf


"" USAGE: noremap <buffer><silent><unique><expr>  <LocalLeader>s  <SID>opfunc_pprint()
"   HACK: <expr> mapping is used to fetch any prefixed count and register.
"   ALSO: avoids using a cmdline -- prevent trigger CmdlineEnter and CmdlineLeave
fun! Jupyter_opfunc_pprint(type='') abort
  " HACK: reuse same function for "opfunc" and for <expr> mapping
  if a:type == ''
    let b:p = getcurpos()
    set operatorfunc=Jupyter_opfunc_pprint
    return 'g@'
  endif

  " [_] TODO: split function into "generic" and "per-keymap" parts
  "   SEE: ~/.cache/vim/dein/repos/github.com/jupyter-vim/jupyter-vim/autoload/jupyter/load.vim
  "   MAYBE: use <SID> for local functions and closures
  " let Fn = {code -> jupyter#SendCode('p('.code.')')}

  let sel_save = &selection
  let reg_save = getreginfo('"')
  let cb_save = &clipboard
  let visual_marks_save = [getpos("'<"), getpos("'>")]
  try
    " HACK(inclusive): to yank exact visual text from '[ till '] marks
    " ALSO(clipboard=): emptied to avoid clobbering the `"*` or `"+` registers
    set clipboard= selection=inclusive
    let vcmds = #{line: "'[V']y", char: "`[v`]y", block: "`[\<c-v>`]y"}
    silent exe 'noautocmd keepjumps normal! ' .. get(vcmds, a:type, '')
    call Jupyter_send_pprint(getreg('"'))
  finally
    call setreg('"', reg_save)
    call setpos("'<", visual_marks_save[0])
    call setpos("'>", visual_marks_save[1])
    let &clipboard = cb_save
    let &selection = sel_save
    call setpos('.', b:p)
  endtry
  " NOTE: "mode()" function returns state after this operator
endf


fun! BufMap_jupyter_vim() abort
  if exists('b:BufMap_jupyter_vim')|return|endif

  "" BET: assign it something short during prolog inside IPython
  " let b:jupyter_live_pprint = '/__import__("just.iji.util").iji.util.print_ret '
  let b:jupyter_live_pprint = '/p '
  " let b:jupyter_live_exec = b:jupyter_live_pprint .'_live()'
  " let b:jupyter_live_exec = 'print(_live())'
  let b:jupyter_live_exec = '_live()'
  let b:jupyter_live_auto = 1

  nnoremap <buffer><silent><unique>  <LocalLeader>z :call Jupyter_connect_buf()<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>Z :JupyterConnect<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>X :JupyterDisconnect<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>r :JupyterRunFile -iG %:p<CR>
  " BET?(no args): <LL>T -> <LL>e == "execute", like __main__
  nnoremap <buffer><silent><unique>  <LocalLeader>T :JupyterRunFile<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>i :JupyterRunFile -niG %:p<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>I :PythonImportThisFile<CR>

  " IDEA: call "_live" on each ",s" save :USAGE:
  " FAIL: doesn't work for current file :: call jupyter#SendCode('%autoreload')
  " BAD: runs _live() even on error during sourcing
  au! jupy BufWritePost <buffer> if b:jupyter_live_auto && Jupyter_connected()| call jupyter#RunFile("-niG", expand('%:p'))|call Jupyter_send_pprint(b:jupyter_live_exec) |en
  nnoremap <buffer><silent><unique>  <LocalLeader>ta :let b:jupyter_live_auto=!b:jupyter_live_auto<Bar>echom b:jupyter_live_auto<CR>

  nnoremap <buffer><silent><unique>  <LocalLeader>f :call Jupyter_send_pprint(b:jupyter_live_exec)<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>J :let b:jupyter_live_exec=getline('.')<Bar>echom b:jupyter_live_exec<CR>
  xnoremap <buffer><silent><unique>  <LocalLeader>J "sy:<C-u>let b:jupyter_live_exec=getreg('s')<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>j :call jupyter#SendCode('%autoreload')<CR>

  nnoremap <buffer><silent><unique>  <LocalLeader>h :JupyterSendCell<CR>
  " nnoremap <buffer><silent><unique>  <LocalLeader>x :JupyterSendCell<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>S :call jupyter#SendCell()\|call jupyter#SendCode(b:jupyter_live_exec)<CR>
  xmap     <buffer><silent><unique>  <LocalLeader>S <Plug>JupyterRunVisual
  nnoremap <buffer><silent><unique>  <LocalLeader>d <Cmd>call jupyter#RunFile("-niG", expand('%:p')) \| call Jupyter_send_pprint(b:jupyter_live_exec)<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>D <Cmd>call Jupyter_send_pprint(b:jupyter_live_exec)<CR>
  " FAIL: doesn't print anything back
  nnoremap <buffer><silent><unique>  <LocalLeader>p <Cmd>call jupyter#RunFile("-niG", expand('%:p')) \| call jupyter#SendCode("%prun -s tottime -l 10 ".b:jupyter_live_exec)<CR>

  " nnoremap <buffer><silent><unique>  <LocalLeader>s :<C-u>set operatorfunc=<SID>opfunc_run_code<CR>g@
  " xnoremap <buffer><silent><unique>  <LocalLeader>s "sy:<C-u>call jupyter#SendCode('p('.getreg("s").')')<CR>
   noremap <buffer><silent><unique><expr>  <Plug>JupyterSendSmart  Jupyter_opfunc_pprint()
   map     <buffer><silent><unique>  <LocalLeader>k  <Plug>JupyterSendSmart
  nmap     <buffer><silent><unique>  <LocalLeader>s  _vg_<Plug>JupyterSendSmart
  xmap     <buffer><silent><unique>  <LocalLeader>s  <Plug>JupyterSendSmart

  "" NOTE: send current line, eval and pprint result
  " nnoremap <buffer><silent><unique><expr>  <LocalLeader>ss Jupyter_opfunc_pprint().."_"
  nmap <buffer><silent><unique>  <Plug>JupyterSendPretty  :<C-u>let b:p=getcurpos()<CR>vil"sy:<C-u>call jupyter#SendCode('p('.getreg("s").')')<Bar>call setpos('.',b:p)<CR>
  nmap     <buffer><silent><unique>  <LocalLeader>kl <Plug>JupyterSendPretty
  nmap     <buffer><silent><unique>  <LocalLeader>kk <Plug>JupyterSendPretty
  " nmap     <buffer><silent><unique>  <LocalLeader>s  <Plug>JupyterSendPretty
  " xmap     <buffer><silent><unique>  <LocalLeader>s <Plug>JupyterRunVisual

  " HACK: send for-loops
  " ALT:XLR:CHG: send all current indent and below ++ single top line (for-loop/if-cond)
  nmap <buffer><silent><unique>  <Plug>JupyterSendOutline  :<C-u>let b:p=getcurpos()<CR>vip:JupyterSendRange<Bar>call setpos('.',b:p)<CR>
  nmap     <buffer><silent><unique>  <LocalLeader>o  <Plug>JupyterSendOutline

  " FIXME: strip("^\s*return\s*") for <LL-l> too
  nnoremap <buffer><silent><unique>  <LocalLeader>l :let b:p=getcurpos()\|JupyterSendRange\|call setpos('.',b:p)<CR>
  xnoremap <buffer><silent><unique>  <LocalLeader>l :JupyterSendRange<CR>
  nmap     <buffer><silent><unique>  <LocalLeader>w <Plug>JupyterRunTextObj
  xmap     <buffer><silent><unique>  <LocalLeader>w <Plug>JupyterRunVisual
  " nmap     <buffer><silent><unique>  <LocalLeader>F <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterFunctionTextObject)
  " nmap     <buffer><silent><unique>  <LocalLeader>C <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterClassTextObject)
  nmap     <buffer><silent><unique>  <LocalLeader>F <Plug>JupyterRunTextObjaf
  nmap     <buffer><silent><unique>  <LocalLeader>C <Plug>JupyterRunTextObjac
  nmap     <buffer><silent><unique>  <LocalLeader>L <Plug>JupyterRunTextObj$
  " nmap     <buffer><silent><unique>  <LocalLeader>i <Plug>JupyterRunTextObj<Plug>(textobj-indent-a)
  nmap     <buffer><silent><unique>  <LocalLeader>G <Plug>JupyterRunTextObj<Plug>(textobj-entire-i)

  " HACK: for integration with Vimspector (:PythonStartDebugger)
  "   https://github.com/jupyter-vim/jupyter-vim/pull/69
   noremap <buffer><silent><unique>  <LocalLeader>B :<C-u>JupyterSendCode 'breakpoint()'<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>b Obreakpoint()<Esc>j
  nnoremap <buffer><silent><unique>  <LocalLeader>vz :PythonStartDebugger<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>tp :call jupyter#SendCode(InferJupyterPkg())<CR>


  call s:mapsendcode('tc', '/len list(', ')')
  call s:mapsendcode('td', '/dir ')
  call s:mapsendcode('te', '')
  call s:mapsendcode('tg', '%debug ')
  nnoremap <buffer><silent><unique>  <LocalLeader>vd :JupyterSendCode '%debug'<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>tj :JupyterSendCode '_live()'<CR>
  call s:mapsendcode('tl', '/list ')
  " call s:mapsendcode('tp', '/p ')
  call s:mapsendcode('tr', "/__import__('pprint').pprint ")
  call s:mapsendcode('ts', 'p(', ')')
  call s:mapsendcode('tt', b:jupyter_live_pprint)
  call s:mapsendcode('tv', '/vars ')
  call s:mapsendcode('tw', '')

  let b:BufMap_jupyter_vim = 1
endf
