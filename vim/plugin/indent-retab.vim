if &cp||exists('g:loaded_retab')|finish|else|let g:loaded_retab=1|endif
" vim:ts=2:sw=2:sts=2
" TODO:
"   call with arg of right ts in which file looks like
"   must be no error when file is already processed

"{{{1 MAPS =================
noremap <unique> [Replace]t  :s:^\t\+:\=repeat(" ", len(submatch(0))*' . &ts . ')<CR>
noremap <unique> [Replace]T  :s:^\( \{'.&ts.'\}\)\+:\=repeat("\t", len(submatch(0))/' . &ts . ')<CR>


"{{{1 CMDS =================
" Render TABs using this many spaces, as indentation on </>
let g:default_indent = 4
" USE :retab to revert effect
" Retab spaced file, but only indentation
command! -bar -nargs=0 RetabSpaces call s:RetabSpaces()
command! -bar -nargs=? RetabIndent call s:RetabIndent(<args>)


"{{{1 IMPL =================
function! s:RetabIndent(...)
  let nt = a:0>0 ? a:1 : g:default_indent
  call s:RetabSpaces()
  exe printf('setl ts=%s sts=%s sw=%s', nt, nt, nt)
  retab
endfunc

" Retab spaced file, but only indentation
func! s:RetabSpaces()
  let saved_view = winsaveview()
  let patt = '^\( \{'.&ts.'}\)\+'
  let repl = '\=repeat("\t", len(submatch(0))/'.&ts.')'
  silent exe '%s@'.l:patt.'@'.l:repl.'@e'
  call winrestview(saved_view)
endfunc


"{{{1 EXPL =================
" to replace all leading spaces as tabs but not to affect tabs after other characters. It assumes that 'ts' is set correctly. You can go a long way to making files that are misaligned better by doing something like this:

" :set ts=8     " Or whatever makes the file looks like right
" :set et       " Switch to 'space mode'
" :retab        " This makes everything spaces
" :set noet     " Switch back to 'tab mode'
" :RetabIndents " Change indentation (not alignment) to tabs
" :set ts=4     " Or whatever your coding convention says it should be

" You'll end up with a file where all the leading whitespace is tabs so people can look at it in whatever format they want, but where all the trailing whitespace is spaces so that all the end-of-line comments, tables etc line up properly with any tab width.

"{{{1 EXPL =================
" Explanation of the 'exe' line:
" execute '%s@^\( \{'.&ts.'}\)\+@\=repeat("\t", len(submatch(0))/'.&ts.')@'
" Execute the result of joining a few strings together:

" %s               " Search and replace over the whole file
" @....@....@      " Delimiters for search and replace
" ^                " Start of line
" \(...\)          " Match group
"  \{...}          " Match a space the number of times in the curly braces
" &ts              " The current value of 'tabstop' option, so:
"                  " 'string'.&ts.'string' becomes 'string4string' if tabstop is 4
"                  " Thus the bracket bit becomes \( \{4}\)
" \+               " Match one or more of the groups of 'tabstop' spaces (so if
"                  " tabstop is 4, match 4, 8, 12, 16 etc spaces
" @                " The middle delimiter
" \=               " Replace with the result of an expression:
" repeat(s,c)      " Make a string that is c copies of s, so repeat('xy',4) is 'xyxyxyxy'
" "\t"             " String consisting of a single tab character
" submatch(0)      " String that was matched by the first part (a number of multiples
"                  " of tabstop spaces)
" len(submatch(0)) " The length of the match
" /'.&ts.'         " This adds the string "/4" onto the expression (if tabstop is 4),
"                  " resulting in len(submatch(0))/4 which gives the number of tabs that
"                  " the line has been indented by
" )                " The end of the repeat() function call
"
" @                " End delimiter
