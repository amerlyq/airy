" SET: 100%
" no global map, only local verbose
"
let g:startify_custom_header = [
    \ 'OPEN: [e]mpty buffer,    [i]nsert, [q]uit',
    \ 'MARK: [b]uffer, [s]plit, [v]split, [t]ab',
    \ 'EX:   :Startify :SLoad :SSave :SDelete',
    \ '']

let g:startify_list_order = [
    \ ['   Recent files:'],
    \ 'files',
    \ ['   Current dir (sort by modified):'],
    \ 'dir',
    \ ['   My bookmarks:'],
    \ 'bookmarks',
    \ ['   Found sessions:'],
    \ 'sessions',
    \ ]

let g:startify_custom_footer = ['',
\ '                __                    __           ___',
\ '               /\ \__                /\ \__  __  /`___\',
\ '           ____\ \ ,_\    __     _ __\ \ ,_\/\_\/\ \__/  __  __',
\ '          /`,__\\ \ \/  /`__`\  /\``__\ \ \/\/\ \ \ ,__\/\ \/\ \',
\ '         /\__, `\\ \ \_/\ \L\.\_\ \ \/ \ \ \_\ \ \ \ \_/\ \ \_\ \',
\ '         \/\____/ \ \__\ \__/.\_\\ \_\  \ \__\\ \_\ \_\  \/`____ \',
\ '          \/___/   \/__/\/__/\/_/ \/_/   \/__/ \/_/\/_/   `/___/> \',
\ '                                                             /\___/',
\ '                                                             \/__/',
\ ]

let g:startify_enable_special = 0

let g:startify_session_dir = '~/.vim/session'
let g:startify_bookmarks = [ '~/.vimrc' ]
let g:startify_files_number = 8

" When the file Session.vim is found in the current directory,
" it will be shown at the top of all lists as entry [0].
let g:startify_session_detection = 1
" Autosave into Session.vim onto exit
let g:startify_session_persistence = 1
let g:startify_change_to_dir = 1
" Commented 'cause it not only shows, but also tries to open relative path which smtm not available
"let g:startify_relative_path = 1

" Colors
hi StartifyBracket ctermfg=240
hi StartifyNumber  ctermfg=215
hi StartifyPath    ctermfg=245
hi StartifySlash   ctermfg=240
hi StartifySpecial ctermfg=240
hi StartifyHeader  ctermfg=114
hi StartifyFooter  ctermfg=240
"hi StartifyFile    ctermfg=111

let g:startify_skiplist = [
    \ 'COMMIT_EDITMSG',
    \ $VIMRUNTIME .'/doc',
    \ 'bundle/.*/doc',
    \ '.vimgolf',
    \ ]

