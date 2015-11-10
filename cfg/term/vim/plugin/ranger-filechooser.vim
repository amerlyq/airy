" Add ranger as a file chooser in vim
"
" If you add this code to the .vimrc, ranger can be started using the command
" ":RagerChooser" or the keybinding "<leader>r". Once you select one or more
" files, press enter (or move right) and ranger will quit again and vim will
" open the selected files.


function! s:open_paths(lines)
  if empty(a:lines) | return | endif
  " Edit the first item.
  exe 'edit ' . fnameescape(a:lines[0])
  " Add any remaning items to the arg list/buffer list.
  for line in a:lines[1:]
      exe 'argadd ' . fnameescape(line)
  endfor
  redraw!
endfunction


function! s:read_file(temps)
try
  if filereadable(a:temps.result)
    let lines = readfile(a:temps.result)
    call s:open_paths(lines)
  else
    let lines = []
  endif

  for tf in values(a:temps)
    silent! call delete(tf)
  endfor

  return lines
catch
  if stridx(v:exception, ':E325:') < 0
    echoerr v:exception
  endif
endtry
endfunction


function! s:getpos()
  return {'tab': tabpagenr(), 'win': winnr(), 'cnt': winnr('$')}
endfunction


function! s:callback(temps)
  let prms = {'buf': bufnr('%'), 'temps': a:temps, 'name': 'Ranger'}
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
      call s:read_file(self.temps)
    endtry
  endf
  return l:prms
endfunction


function! s:execute_term(cmd, temps)
  let s:ppos = s:getpos()
  tabnew  " OR tabnew
  setlocal winfixwidth winfixheight buftype=nofile bufhidden=wipe nobuflisted
  if 0 < termopen(a:cmd, s:callback(a:temps))
    setf iav_term
    startinsert
  endif
  return []
endfunction


function! s:warn(msg)
  echohl WarningMsg
  echom a:msg
  echohl None
endfunction


function! RangeChooser()
  let temps = {'result': tempname()}
  let cmd = 'ranger --choosefiles='.shellescape(temps.result)
  if has('nvim')
    if bufexists('term://*:FZF')
      call s:warn('FZF is already running!')
      return []
    endif
    " MAPS: au TermOpen term://*fzf tnoremap <buffer> ...
    call s:execute_term(cmd, temps)
  else
    exe 'Silent ' . cmd
    call s:open_paths(s:read_file(temps))
  endif
endfun

command! -bar RangerChooser call RangeChooser()
