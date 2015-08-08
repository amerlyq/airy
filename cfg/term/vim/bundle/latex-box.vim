let g:LatexBox_output_type = "pdf"
let g:LatexBox_quickfix = 2
"let g:LatexBox_latexmk_async = 1
let g:LatexBox_latexmk_preview_continuously = 1
let g:LatexBox_Folding = 0

" Disable annoying behaviour of latex symbol conversion in vim
let g:tex_conceal = ""

" The string is expanded by vim, with reference to the expand() help topic
" see |cmdline-special| and |expr-string|.
" It should be solved now. The problem was that with async mode, we use silent execute command,
" which requires one layer of escaping more than system(cmd) which is used when async=0.

let g:LatexBox_latexmk_options ="-pdflatex='pdflatex -synctex=1 \\%O \\%S'"  " -file-line-error

" see $ synctex edit help, -n ?
let g:LatexBox_viewer = 'zathura -x "vim --servername synctex --remote-silent +\\%{line} \\%{input} >/dev/null 2>&1"'

" https://bbs.archlinux.org/viewtopic.php?pid=800460
" http://stackoverflow.com/questions/14466395/making-vim-mappings-quiet

"   1. Add smwr at first few lines of each file
"       %! TEX root = main.tex
"   2. Create an empty file in the same directory.
"       main.tex.latexmain
"   3. Use vim env var
"       let b:main_tex_file ="~/aura/erian/dev/diplom/main.tex"

" expand("%:p:h")
" Navigate in pdf to current vim position
noremap <silent> \s :silent
    \ ! zathura --synctex-forward
    \ "<C-R>=line(".")<CR>:1:%:p"
    \ "<C-R>=LatexBox_GetOutputFile()<CR>"
    \ <CR> <C-L>
" --synctex-pid 15542 > /dev/null
