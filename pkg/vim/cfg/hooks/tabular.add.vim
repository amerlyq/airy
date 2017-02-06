" Provides extra :Tabularize commands

noremap         <unique>  [Frame]A  :Tabularize /<C-R>//l1r1
noremap         <unique>  [Frame]gA :Tabularize /^[^:]*\zs:/l0c1r0
noremap <silent><unique>  [Frame]a  :<C-U>Tabi<CR>
noremap <silent><unique>  [Frame]ga :<C-U>Tabi!<CR>
noremap <silent><unique>  [Frame]g: :Tabularize /:\s*\zs\S/l1l0<CR>
noremap <silent><unique>  [Frame]g# :Tabularize /#\ze[^#]*$/l2l1<CR>
noremap <silent><unique>  [Frame]g<bar> :Tabularize /<bar>/l1l1<CR>
