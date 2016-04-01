" WARNING This will prevent you from writing such pairs at all (even paste)!
" So, to paste text with them from term you need use 'set paste'
" ALSO: there is corner cases, when it behaves weirdly
" -- Pressing is easier and less stretching.
" -- BUT typing is more difficult and errorprone
" -- Especially when words beg/end in jf/fj
inoremap jf <Esc>
inoremap fj <Esc>

" inoremap jj <Esc>
" cnoremap <expr> j  getcmdline()[getcmdpos()-2] ==# 'j' ? "\<BS>\<C-c>" : 'j'
" onoremap jj           <ESC>
" inoremap j<Space>     j
" onoremap j<Space>     j
