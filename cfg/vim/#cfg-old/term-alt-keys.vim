" DEPRECATED:
" - Too much bugs in caused by every seen implementation
" - Clushes with terminal escape codes, insert mode, etc
" - Use <Alt/Meta> for urxvt/tmux only, not necessary in vim
" - For gvim use <Alt> only for gui-specific mappings


" vim: fdm=marker
" Based on vim tip 1272 [http://vim.wikia.com/wiki/VimTip1272]
" See: http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim
" See: :h <Char> -- how to use direct code mapping for multibyte: <S-Char-114>

" NOTE: Alt-c and Alt-C -- different
"" fix meta-keys which generate <Esc>[0-9A-Za-z]


if has("gui_running") || exists("did_meta_escape") | finish | endif
let did_meta_escape = 1

" Keycodes {{{1

" Note that using this is only necessary if you are using a terminal emulator
" that sends escape-char for the alt/meta key. Many (all) of the rxvt
" derivitives do this by default. Xterm can do this if the eightBitInput is
" false or metaSendsEscape is true (along with a couple other ways). Not sure
" about kterm, gnome-terminal or some of the others do it. To check just hit
" <C-v> <M-a> and if it produces 'a' then this will help you. If it instead
" produces 'á' then you don't need this script.

let s:keys = map(range(97, 122), "nr2char(v:val)") " a-z
let s:keys += map(range(48, 57), "nr2char(v:val)")  " 0-9

" Note that you can add other characters here. There are some to avoid
" however. Capitol 'O' causes problems with the arrow keys. The '['
" character just doesn't work. There are probably others, you'll just have
" to do some testing.

" Try to get the best dead keycodes per terminal type
if &term == 'xterm'
    " 58 keycodes, xterm sends shift-fkeys for shift-fkeys
    let s:key_codes = map(range(13,37), '"<S-F".v:val.">"')
            \+ map(range(13,37), '"<F".v:val.">"')
"           \+ map(range(1,4), '"<xF".v:val.">"')
"           \+ map(range(1,4), '"<S-xF".v:val.">"')
else
    " 62 keycodes, rxvtish terms send f11-20 for shift-fkeys
    " (Origin was: 1..37, 21..37 -- But my urxvt is customized)
    let s:key_codes = map(range(13,37), '"<S-F".v:val.">"')
            \+ map(range(13,37), '"<F".v:val.">"')
"           \+ map(range(1,4), '"<xF".v:val.">"')
"           \+ map(range(1,4), '"<S-xF".v:val.">"')
endif

"" Additional possible vim keycodes to use {{{1
"" weird misc keys. work with shift and control
"let s:misc = ['xHome', 'zHome', 'xEnd', 'zEnd']
"" work with shift
"let s:odd = ['Help', 'Undo']
"" keypad keys - usable here with laptop keyboards and like
"let s:keypad = ['kHome', 'kEnd' ]
"            \+ ['kInsert', 'kDel', 'kPageUp', 'kPageDown']
"            \+ ['kPlus', 'kMinus', 'kDivide', 'kMultiply']
"            \+ ['kEnter', 'kPoint']
"            \+ map(range(0,9), '"k".v:val')
"let s:key_codes += map(range(1,4), '"<xF".v:val.">"')
"            \+ map(range(1,4), '"<S-xF".v:val.">"')
"            \+ map(s:misc[:], '"<S-".v:val.">"')
"            \+ map(s:misc[:], '"<C-".v:val.">"')
"            \+ map(s:misc, '"<".v:val.">"')
"            \+ map(s:odd[:], '"<S-".v:val.">"')
"            \+ map(s:odd, '"<".v:val.">"')
"            \+ map(s:keypad, '"<".v:val.">"')

"echo len(s:keys)
"echo len(s:key_codes)

" Actual Map {{{1
for idx in range(len(s:keys))
    let pc = s:keys[idx]
    let kc  = s:key_codes[idx]
    exec "set ".kc."=\e".pc
    exec "map ".kc." <M-".pc.">"
    "" DISABLED: due to interpreting <Esc>j etc as unicode when returning
    ""           too fast from insert mode. Same always present on macro exec.
    " exec "map! ".kc." <M-".pc.">"
endfor

" NOTE: {{{1
"" To fix delay on leave insert-mode, there are too different workarounds:
" 1. Map <ESC> to \033\015 or \033\007 in .Xresources, then add in ranger some
"       copy?map <ESC> ... <C-g>
" 2. Use snip-insert-autoleave@FastEscape
" When it will not work again, see ':h term'

" As alternative for Alt, there are plugin, doing somewhat more, then I do.
" It has some nice ideas (about F13-F37 reusing for map), but inefficient code
"  https://github.com/drmikehenry/vim-fixkey

"" Show all chars
" for i in range(32,126) | $put =nr2char(i) | endfor
"  http://vim.wikia.com/wiki/Making_a_list_of_numbers

