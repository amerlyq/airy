" Name: Notches
" Fast highlighting: match Error /ENOMEM/

if &cp||exists('g:loaded_notches')|finish|else|let g:loaded_notches=1|endif
if !has('autocmd') || v:version <= 701 | finish | endif

" UNUSED: 7,15 - whites, 0,8 - blacks, 11,12,14 - grays
let s:patterns = [
  \ ['Err', 196, '#ff2525', 'ERR%(OR)?|BUG|REGR|XXX|WTF|BAD|FAIL%(ED)?|CRIT%(ICAL)?'],
  \ ['Add',  76, '#5faf00', 'ADD|SEE|READ|REF|TUT|BLOG|NEED|FIND|ALSO|BET%(TER)?|E\.G'],
  \ ['Alt', 178, '#dfaf00', 'ALT|OR|CASE|THINK|IDEA|CHG|CMP|I\.E|EXAM%(INE)?'],
  \ ['Dev',  33, '#0087ff', 'DEV|ENH%(ANCE)?|HACK|RFC|SEP%(ARATE)?|SPL%(IT)?|DECIDE'],
  \ ['Tbd', 169, '#ff5faf', 'TODO|CHECK|TRY|MOVE|NOT|REQ%(UIRE)?|MAYBE'],
  \ ['Inf',  38, '#00afdf', 'INFO?|VAR|VIZ|ALG|IMPL'],
  \ ['Fix', 202, '#ff5f00', 'BUT|FIX%(ME)?|WARN%(ING)?|ATT%(ENTION)?|REM%(OVE)?'],
  \ ['Did', 243, '#767676', 'DONE|FIXED|EXPL%(AIN)?|TEMP|UNUSED|OBSOL%(ETE)?|DEPR%(ECATED)?'],
  \ ['Msg',  62, '#5f5fdf', 'NOTE|USE|USAGE|DFL|STD|SUM%(MARY)?|DEBUG|I\.A|DEP%(ENDS)?'],
  \]
" check = prove = assert = verify
" check:maybe = lemma = assumption = guess = conjecture = hypothesis
" Latin abbrev: SEE https://en.wikipedia.org/wiki/List_of_Latin_abbreviations
" E.G. exampli gratia (~ example given)
" I.E. id est (~ in especial, effectively)
" I.A. inter alia (~ among other things)
" VIZ. videlicet (~ precisely: implies (near) completeness)

function! s:everywhere_print(patts)
  tabnew
  setl buftype=nofile bufhidden=wipe nobuflisted
  for [k,c,g,p] in a:patts
    call append(line('.'), k .': '. p)
  endfor
endfunction


function! s:everywhere_define(patts)
  let locals = 'term=bold cterm=bold gui=bold'
  for [k,c,g,p] in a:patts  "term=bold,underline guifg=#E01B1B
    exec printf('hi! Notch%s %s ctermfg=%s guifg=%s', k, locals, c, g)
  endfor
endfunction


function! s:everywhere_matches(patts)
  for [k,c,g,p] in a:patts
    call matchadd('Notch'. k, '\v<('.p.')>[:?!*.=]*', -1)
  endfor
endfunction


function! s:everywhere_enable(mode)
  let g:everywhere_activated = a:mode
  augroup EverywhereNotches
    autocmd!
    if g:everywhere_activated
      au Syntax * call s:everywhere_matches(s:patterns)
      au ColorScheme * call s:everywhere_define(s:patterns)
    endif
  augroup END
endfunction


let g:everywhere_activated = 1
call s:everywhere_define(s:patterns)
call s:everywhere_enable(1)
" autocmd WinEnter,VimEnter * call s:everywhere_enable(1)

command! -bar -bang -nargs=0 EverywhereNotchesToggle
  \ call s:everywhere_enable(!g:everywhere_activated)|syntax off|syntax on

command! -bar -bang -nargs=0 EverywhereNotchesList
  \ call s:everywhere_print(s:patterns)|syntax off|syntax on

nnoremap <unique> [Toggle]T :EverywhereNotchesToggle<CR>
