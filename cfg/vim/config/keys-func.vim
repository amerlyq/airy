
" For when you forget to sudo.. Really Write the file.
cnoremap e!! e !sudo tee %
cnoremap w!! w !sudo tee % >/dev/null

" Change Working Directory to that of the current file
noremap \cwd :lcd %:p:h

" generate 'tags' file: obsolete by easytags
nnoremap <silent> <F1> :!ctags-exuberant --recurse<CR>

" reload updated settings in running vim instance
nnoremap <S-F1> :autocmd! * \| source $MYVIMRC \| AirlineRefresh<CR>
" make current vim as the main server
nnoremap <S-F2> :call writefile([v:servername], expand("~/.cache/vim/servername"), "b") \| echo "ServerName: " . v:servername<CR>
nnoremap <S-F3> :e $VIMHOME/snippets/vim_regex.otl<CR>

"http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=memcpy

noremap <F6> :setlocal spell! spelllang=uk,en_us,ru_yo<CR>
imap <F6> <C-O><F6>

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


command! -bar -nargs=? MapDump redir > ~/vim_map_dump | map <args> | redir END
