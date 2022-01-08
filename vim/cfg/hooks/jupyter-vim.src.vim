
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
  nnoremap <buffer><silent><unique>  <LocalLeader>s :call jupyter#SendCell()\|call jupyter#SendCode(g:jupyter_live_exec)<CR>
  xmap     <buffer><silent><unique>  <LocalLeader>s <Plug>JupyterRunVisual

  nnoremap <buffer><silent><unique>  <LocalLeader>l :let b:p=getcurpos()\|JupyterSendRange\|call setpos('.',b:p)<CR>
  xnoremap <buffer><silent><unique>  <LocalLeader>l :JupyterSendRange<CR>
  nmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunTextObj
  xmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunVisual
  nmap     <buffer><silent><unique>  <LocalLeader>f <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterFunctionTextObject)
  nmap     <buffer><silent><unique>  <LocalLeader>c <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterClassTextObject)
  nmap     <buffer><silent><unique>  <LocalLeader>L <Plug>JupyterRunTextObj$
  " nmap     <buffer><silent><unique>  <LocalLeader>i <Plug>JupyterRunTextObj<Plug>(textobj-indent-a)
  nmap     <buffer><silent><unique>  <LocalLeader>G <Plug>JupyterRunTextObj<Plug>(textobj-entire-i)

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
  call s:mapsendcode('ts', g:jupyter_live_pprint)
  call s:mapsendcode('tv', '/vars ')
  call s:mapsendcode('tw', '')
endf
