
" As simple as Ctrl-S under Win,
" {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <Leader>s :write ++enc=utf8<CR>
noremap <Leader>S :saveas<Space>

" Swap registry
noremap <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>
" Remap line-up and move-up
noremap <C-y> :let @+=@" \| echom @+<CR>
noremap <C-p> :let @"=@+ \| echom 'Copied:' @"<CR>

" For when you forget to sudo.. Really Write the file.
cnoremap e!! e !sudo tee %
cnoremap w!! w !sudo tee % >/dev/null

" generate 'tags' file: obsolete by easytags
nnoremap <silent> <F1> :!ctags-exuberant --recurse<CR>
" reload updated settings in running vim instance
nnoremap <M-F1> :source $MYVIMRC<CR>
"nmap <silent> <leader>sv :so $MYVIMRC<CR>

" set makeprg=ruby\ -c\ %
noremap <silent> <F5> <Esc>:w\|make -C <C-R>=getcwd()<CR>/build \|cw<CR>
noremap <F6> :setlocal spell! spelllang=uk,en_us,ru_yo<CR>

nnoremap <leader>jt <Esc>:%!python -m json.tool<CR><Esc>:set filetype=json<CR>

" repeat last character to the maximum width of current line
nnoremap <Leader>_ :execute 's/.$/'. repeat('&', &textwidth+1) .'/'<Enter>
      \:execute 's/\%>'. &textwidth .'v.//g'<Enter>

" insert or update section separator at end of current line
nmap <Leader>- A-<Esc><Leader>_

" format current line as a top-level heading in markdown (uses `z marker)
nmap <Leader>= mzyypVr=:.+1g/^=\+/d<Enter>`z
" format current line as a second-level heading in markdown (uses `z marker)
nmap <Leader>+ mzyypVr-:.+1g/^-\+/d<Enter>`z
