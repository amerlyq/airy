" Integration with urxvt to receive focus events in vim
" http://karma-lab.net/creer-plugin-urxvt-sauvegarder-vim-automatiquement

" WARNING:
" If you lost focus when in ':' or '/' mode, that string will be polluted by escape-codes.

" TODO:
"   disable when has('gui') or 'term!=urxvt'
"   think about how to disable those commands (or make them not harmful) if plugin is absent
" TODO: map -- very inefficient approach. Better do like here:
"   http://karma-lab.net/faire-quelque-chose-dutile-capslock

" Initialisation du mode "focus"
exe 'silent !echo -ne "\033]777;focus;on\007"'

" Gestion de la séquence focusin/focusout
" map  ^[[UlFocusIn :bufdo checktime<CR>
" map  ^[[UlFocusOut :wa!<CR>
" map! ^[[UlFocusIn <C-O>:bufdo checktime<CR>
" map! ^[[UlFocusOut <C-O>:wa!<CR>

map  ^[[UlFocusIn   :<C-u>echom 'IN'<CR>
map  ^[[UlFocusOut  :<C-u>echom 'OUT'<CR>
map! ^[[UlFocusIn   <C-O>:echom 'IN'<CR>
map! ^[[UlFocusOut  <C-O>:echom 'OUT'<CR>

" Désactivation du mode focus en partant
autocmd VimLeavePre * exe 'silent !echo -ne "\033]777;focus;off\007"'

