
function! CountCopyLines()
    " let d={'num': 0}
    "call substitute(@+, '$', '\=extend(d, {"num": d.num+1}).num', 'g')
    " let s= substitute(expand(@+), '$', '\=extend(d, {"num": d.num+1}).num', 'g')
    let s = split(@+, '\n\zs')
    let n = len(s)
    let l = s[0]
    " let s = string(s[0])
    " let n=[0]
    " let s = substitute(@+, "^\zs", "\=map(n,'v:val+1')[1:]", "ge")


    " let num = 0    " total # of matches in the buffer
    " let s_opt = 'Wc'
    " while search(@/, s_opt)
    "     let num = num + 1
    "     let s_opt = 'W'
    " endwh

    return n . l
    "d.num
endfunction

" Remap line-up and move-up
" on visual area it must copy instantly! and only in @+
function! Ssdfs(s)
  " let n=[0]
  " bufdo %s/pattern\zs/\=map(n,'v:val+1')[1:]/ge
  " let msg = substitute(@+, "^\zs", "\=map(n,'v:val+1')[1:]", "ge")
  " let msg = substitute(@+, '@', '\r', 'n')
  " let msg = %s/^//n
    " let n = len(split(@+, '^', 1)) - 1
  echom a:s . CountCopyLines()
endfunction

noremap <C-y> :let @+=@" \| :call Ssdfs('Push ')<CR>
noremap <C-p> :let @"=@+ \| :call Ssdfs('Pull ') <CR>
