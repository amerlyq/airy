" NOTE: Alt-c and Alt-C -- different
"" fix meta-keys which generate <Esc>[0-9A-Za-z]
if !has('gui_running')
  for i in range(35,61) + range(65,90) + range(97,122)
    let c = nr2char(i) " echom i c
    exec "set <M-".c.">=\e".c
    " Shadowed 'cause of some wierd behaviour as 'No such mapping'
    " exec "map  \e".c." <M-".c.">"
    " exec "map! \e".c." <M-".c.">"
  endfor
endif

"" To fix delay on leave insert-mode, there are too different workarounds:
" 1. Map <ESC> to \033\015 or \033\007 in .Xresources, then add in ranger some
"       copy?map <ESC> ... <C-g>
" 2. Use snip-insert-autoleave@FastEscape
"
" When it will not work again, see ':h term'

" As alternative for Alt, there are plugin, doing somewhat more, then I do.
" It has some nice ideas (about F13-F37 reusing for map), but inefficient code
"  https://github.com/drmikehenry/vim-fixkey

"" Show all chars
" for i in range(32,126) | $put =nr2char(i) | endfor
"  http://vim.wikia.com/wiki/Making_a_list_of_numbers

" To find last mapping of keys
" :verbose nmap <C-[>
