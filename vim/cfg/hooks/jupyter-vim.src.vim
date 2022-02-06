
let g:jupyter_mapkeys = 0

"" BET: assign it something short during prolog inside IPython
" let g:jupyter_live_pprint = '/__import__("just.iji.util").iji.util.print_ret '
let g:jupyter_live_pprint = '/p '
let g:jupyter_live_exec = g:jupyter_live_pprint .'_live()'
" let g:jupyter_live_exec = 'print(_live())'
" let g:jupyter_live_exec = '_live()'


autocmd MyAutoCmd FileType python call BufMap_jupyter_vim()

" \\n    noremap  <silent> <Plug>JupyterRunVisual     :<C-u>call <SID>opfunc_run_code(visualmode())<CR>gv
" \\n    nnoremap <buffer><silent><unique>  <LocalLeader>U :JupyterUpdateShell<CR>

fun! s:mapsendcode(k, pfx, ...) abort
  exe 'nnoremap <buffer><silent><unique>  <LocalLeader>'.a:k.' :call jupyter#SendCode("'.a:pfx.'".expand("<cexpr>")."'.get(a:,1,"").'")<CR>'
  exe 'xnoremap <buffer><silent><unique>  <LocalLeader>'.a:k.' "sy:<C-u>call jupyter#SendCode("'.a:pfx.'".getreg("s")."'.get(a:,1,"").'")<CR>'
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
  let Fn = {code -> jupyter#SendCode('p('.code.')')}

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
    call Fn(getreg('"'))
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
  if exists('b:BufMap_jupyter_vim')|return|else|let b:BufMap_jupyter_vim=1|endif

  nnoremap <buffer><silent><unique>  <LocalLeader>z :JupyterConnect<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>Z :JupyterDisconnect<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>r :JupyterRunFile -iG %:p<CR>
  " BET?(no args): <LL>T -> <LL>e == "execute", like __main__
  nnoremap <buffer><silent><unique>  <LocalLeader>T :JupyterRunFile<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>i :JupyterRunFile -niG %:p<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>I :PythonImportThisFile<CR>

  nnoremap <buffer><silent><unique>  <LocalLeader>vd :JupyterSendCode '%debug'<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>tj :JupyterSendCode '_live()'<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>j :call jupyter#SendCode(g:jupyter_live_exec)<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>J :let g:jupyter_live_exec=getline('.')<CR>
  xnoremap <buffer><silent><unique>  <LocalLeader>J "sy:<C-u>let g:jupyter_live_exec=getreg('s')<CR>

  nnoremap <buffer><silent><unique>  <LocalLeader>h :JupyterSendCell<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>x :JupyterSendCell<CR>
  nnoremap <buffer><silent><unique>  <LocalLeader>S :call jupyter#SendCell()\|call jupyter#SendCode(g:jupyter_live_exec)<CR>
  xmap     <buffer><silent><unique>  <LocalLeader>S <Plug>JupyterRunVisual

  " nnoremap <buffer><silent><unique>  <LocalLeader>s :<C-u>set operatorfunc=<SID>opfunc_run_code<CR>g@
  " xnoremap <buffer><silent><unique>  <LocalLeader>s "sy:<C-u>call jupyter#SendCode('p('.getreg("s").')')<CR>
   noremap <buffer><silent><unique><expr>  <LocalLeader>s  Jupyter_opfunc_pprint()

  "" NOTE: send current line, eval and pprint result
  "" [_] MAYBE: trim() assignment on the left to print only results of expr
  " nnoremap <buffer><silent><unique><expr>  <LocalLeader>ss Jupyter_opfunc_pprint().."_"
  nmap     <buffer><silent><unique>  <LocalLeader>ss :<C-u>let b:p=getcurpos()<CR>vil"sy:<C-u>call jupyter#SendCode('p('.getreg("s").')')<Bar>call setpos('.',b:p)<CR>

  nnoremap <buffer><silent><unique>  <LocalLeader>l :let b:p=getcurpos()\|JupyterSendRange\|call setpos('.',b:p)<CR>
  xnoremap <buffer><silent><unique>  <LocalLeader>l :JupyterSendRange<CR>
  nmap     <buffer><silent><unique>  <LocalLeader>w <Plug>JupyterRunTextObj
  xmap     <buffer><silent><unique>  <LocalLeader>w <Plug>JupyterRunVisual
  nmap     <buffer><silent><unique>  <LocalLeader>f <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterFunctionTextObject)
  nmap     <buffer><silent><unique>  <LocalLeader>c <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterClassTextObject)
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
  call s:mapsendcode('tl', '/list ')
  " call s:mapsendcode('tp', '/p ')
  call s:mapsendcode('tr', "/__import__('pprint').pprint ")
  call s:mapsendcode('ts', 'p(', ')')
  call s:mapsendcode('tt', g:jupyter_live_pprint)
  call s:mapsendcode('tv', '/vars ')
  call s:mapsendcode('tw', '')
endf
