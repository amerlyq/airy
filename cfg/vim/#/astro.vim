" Moving up/down by function, unfolding current function but folding all else
noremap [[  [[zMzvz.
noremap ]]  ]]zMzvz.


" Transferring blocks of text between vim sessions
nmap <Leader>xr   :r $HOME/.vimxfer<CR>
nmap <Leader>xw   :'a,.w! $HOME/.vimxfer<CR>
vmap <Leader>xw   :w! $HOME/.vimxfer<CR>
nmap <Leader>xa   :'a,.w>> $HOME/.vimxfer<CR>
vmap <Leader>xa   :w>> $HOME/.vimxfer<CR>
nmap <Leader>xS   :so $HOME/.vimxfer<CR>
nmap <Leader>xy   :'a,.y *<CR>
vmap <Leader>xy   :y *<CR>
