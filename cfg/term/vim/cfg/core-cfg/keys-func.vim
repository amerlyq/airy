" For when you forget to sudo.. Really Write the file.
command! -bar -bang -nargs=0 Sw silent write !sudo tee % >/dev/null
" Execute command and place output in new buffer. (:new, :vnew, :tabnew)
command! -bar -nargs=+ E new | r ! <args>

cnorea  man  Man

" Show highlight names under cursor
map <F3> :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
    \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
    \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>

" reload updated settings in running vim instance
" nnoremap <S-F1> :autocmd! * \| source $MYVIMRC \| AirlineRefresh<CR>
" make current vim as the main server
nnoremap <S-F2> :call writefile([v:servername], expand("~/.cache/vim/servername"), "b") \| echo "ServerName: " . v:servername<CR>

"http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=memcpy

" nnoremap <leader>jt <Esc>:%!python -m json.tool<CR><Esc>:set filetype=json<CR>

" repeat last character to the maximum width of current line
nnoremap <Leader>_ :execute 's/.$/'. repeat('&', &textwidth+1) .'/'<Enter>
      \:execute 's/\%>'. &textwidth .'v.//g'<Enter>

" insert or update section separator at end of current line
nmap <Leader>- A-<Esc><Leader>_

" format current line as a top-level heading in markdown (uses `z marker)
nmap <Leader>= mzyypVr=:.+1g/^=\+/d<Enter>`z
" format current line as a second-level heading in markdown (uses `z marker)
nmap <Leader>+ mzyypVr-:.+1g/^-\+/d<Enter>`z

" Dump all keymaps
command! -bar -nargs=? MapDump redir > ~/vim_map_dump | map <args> | redir END
" ALT command! FormatJSON %!python -m json.tool
command! FormatJSON %!python -c 'import json, sys;
      \ print(json.dumps(json.load(sys.stdin), indent=2, ensure_ascii=False))'
command! -bar -nargs=? Format2 set ts=2 sw=2 sts=2 fdl=99

"" Append modeline to EOF
" nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

" DEV TRY redirect any vim command (like g] for tags) into new buffer to search
"   ALT redirect into quickfix list
fun! RedirectOutput(cmd)
  redir => _
  silent! exe a:cmd
  redir END
  return _
endf
command! -bar -range -nargs=+  R  call RedirectOutput(<q-args>)
command! -bar -range -nargs=+  Rc
      \ call setreg('+', RedirectOutput(<q-args>), getregtype('+'))

fun! MapFiltered(cmd)
  let _ = RedirectOutput('map '.a:cmd)
  let ms = filter(split(_, '\n'), 'match(v:val, "\\c^...\\S*<Plug>")')
  " let command_names = join(map(split(_, '\n')[1:],
  "       \ "matchstr(v:val, '[!\"b]*\\s\\+\\zs\\u\\w*\\ze')"))
  tabnew | setl wfw wfh buftype=nofile bufhidden=wipe nobuflisted
  call append(0, l:ms)
endf
command! -bar -range -nargs=*  Map  call MapFiltered(<q-args>)


" Remaps gm so the cursor is moved to the middle of the current physical line.
" Any leading or trailing whitespace is ignored: the cursor moves to the middle
" of the text between the first and last non-whitespace characters.
function! s:Gm()
  execute 'normal! ^'
  let first_col = virtcol('.')
  execute 'normal! g_'
  let last_col  = virtcol('.')
  execute 'normal! ' . (first_col + last_col) / 2 . '|'
endfunction
noremap  <unique><silent> gM gm
nnoremap <unique><silent> gm :call <SID>Gm()<CR>
onoremap <unique><silent> gm :call <SID>Gm()<CR>
