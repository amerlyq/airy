" For when you forget to sudo.. Really Write the file.
command! -bar -bang -nargs=0 Sw write !sudo tee % >/dev/null
" Execute command and place output in new buffer. (:new, :vnew, :tabnew)
command! -bar -nargs=+ E new | r ! <args>

" Show highlight names under cursor
map <F3> :echo 'hi<'.synIDattr(synID(line('.'), col('.'), 1), 'name')
    \.'> trans<'.synIDattr(synID(line('.'), col('.'), 0), 'name').'> lo<'
    \.synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'<CR>

" reload updated settings in running vim instance
nnoremap <S-F1> :autocmd! * \| source $MYVIMRC \| AirlineRefresh<CR>
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
