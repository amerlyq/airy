if &cp||exists('g:loaded_ishell')|finish|else|let g:loaded_ishell=1|endif

"{{{1 MAPS ====================
noremap <unique><silent>  <Leader>z :<C-U>Z<CR>
noremap <unique><silent>  <Leader>Z :<C-U>Z!<CR>
noremap <unique><silent> g<Leader>z :<C-U>Z!!<CR>


"{{{1 CMDS ====================
command! -bang -bar -nargs=? Z call Ishell(<bang>0, <q-args>)


"{{{1 IMPL ====================

function! s:getpos()
  return {'tab': tabpagenr(), 'win': winnr(), 'cnt': winnr('$')}
endfunction

function! s:callback(temps)
  let prms = {'buf': bufnr('%'), 'temps': a:temps, 'name': 'Ishell'}
  fun! prms.on_exit(id, code)
    let pos = s:getpos()
    let inplace = pos == s:ppos " {'window': 'enew'}
    if !inplace
      if bufnr('') == self.buf |    close | endif
      if pos.tab == s:ppos.tab | wincmd p | endif
    endif
    try
      if inplace && bufnr('') == self.buf
        " exe "normal! \<c-^>"
        " No other listed buffer
        if bufnr('') == self.buf | bd! | endif
      endif
    endtry
  endf
  return l:prms
endfunction


function! s:execute_term(cmd, temps, spl)
  let s:ppos = s:getpos()
  if a:spl | if (winwidth(0)-2-&fdc-(&nu?&nuw:0)) < 80 |new|el|vnew|en
  else | tabnew | endif
  setlocal winfixwidth winfixheight buftype=nofile bufhidden=wipe nobuflisted
  if 0 < termopen(a:cmd, s:callback(a:temps))
    setf iav_term
    startinsert
  endif
  return []
endfunction


function! Ishell(gcwd, cmd)
  let l:temps = {'result': tempname()}
  let l:path = expand(a:gcwd ? '%:p:h' : getcwd(), 1)
  let l:spl = (a:cmd !~# '^!\s*$')

  let l:cmdline = 'unset RANGER_LEVEL;$SHELL'
  let l:cmd = (l:spl ? a:cmd : a:cmd[1:])
  if l:cmd !~# '\s*'
    let l:cmdline .= ' -c '.shellescape(l:cmd)
  endif

  let l:cd_old = getcwd()
  exe 'cd' fnameescape(l:path)
  try
    if has('nvim')
      call s:execute_term(l:cmdline, l:temps, l:spl)
    else
      exe 'sh' l:cmdline
    endif
  finally
    exe 'cd' l:cd_old
  endtry
endfun
