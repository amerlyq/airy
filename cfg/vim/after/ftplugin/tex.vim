setlocal spell
setlocal spelllang=uk,en_us,ru_yo
setlocal iskeyword+=:

" else there will be 'cant open error file'
" set shell=bash
" set modelines

imap <buffer> [[     \begin{
imap <buffer> ]]     <Plug>LatexCloseCurEnv
nmap <F5>            <Plug>LatexToggleStarEnv
vmap <buffer> <F7>   <Plug>LatexWrapSelection
imap <buffer> ([     \eqref{
imap <buffer> ((     \left(
imap <buffer> ))     \item

"SyntasticToggleMode
" I have disabled Syntastic by default and activate/disable error checking with the following in my .vimrc:
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [], 'passive_filetypes': [] }
