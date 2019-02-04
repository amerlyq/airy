" Name: Notches
" Fast highlighting: match Error /ENOMEM/
" SEE: https://github.com/inkarkat/vim-mark
"%USAGE: show all notches :: execute ":/#.*\u\{3,}:", then ":Fs"

if &cp||exists('g:loaded_notches')|finish|else|let g:loaded_notches=1|endif
if !has('autocmd') || v:version <= 701 | finish | endif

" EXPL: used <DECI> because DEC==decrement/decrease
" IDEA: mark text by color specified in notch
"   'RED: ...' -- marker only
"   'GREN! ...' -- rest of line
"   '!CYAN! ...' -- whole line from beginning

" UNUSED: 7,15 - whites, 0,8 - blacks, 11,12,14 - grays
let s:patterns = [
  \ ['Err', 196, '#ff2525', 'RED|RQ|ERR%(OR)?|BUG|REGR|XXX|WTF|BAD|FAIL%(ED)?|CRIT%(ICAL)?'],
  \ ['Add',  76, '#5faf00', 'GREN|ADD|NEED|FIND|ALSO|BET%(TER)?|E\.G|e\.g'],
  \ ['Ref',  28, '#00af00', 'SEE|READ|REF|TUT|BLOG|BOOK|LIOR'],
  \ ['Alt', 178, '#dfaf00', 'YELW|ALT|OR|CASE|THINK|IDEA|CHG|CMP|I\.E|i\.e|EXAM%(INE)?'],
  \ ['Dev',  33, '#0087ff', 'BLUE|DEV|CFG|ENH%(ANCE)?|HACK|RFC|SEP%(ARATE)?|SPL%(IT)?|DECI%(DE)?'],
  \ ['Tbd', 169, '#ff5faf', 'PINK|TODO|CHECK|TRY|MOVE|NOT|REQ%(UIRE)?|MAYBE'],
  \ ['Inf',  38, '#00afdf', 'CYAN|INFO?|SRC|VARs?|VIZ|ALG|HYPO?|IMPL|ARCH|TALK|SECU%(RE|RITY)?|MMAP'],
  \ ['Fix', 202, '#ff5f00', 'ORNG|BUT|DONT|FIX%(ME)?|WARN%(ING)?|ATT%(ENTION)?|REM%(OVE)?'],
  \ ['Did', 243, '#767676', 'GREY|DONE|FIXED|EXPL%(AIN)?|TEMP|UNUSED|OBSOL%(ETE)?|DEPR%(ECATED)?|TL;DR'],
  \ ['Msg',  62, '#5f5fdf', 'PURP|NOTE|USE|USAGE|DFL|STD|SUM%(MARY)?|DEBUG|I\.A|i\.a|DEP%(ENDS)?'],
  \]

" check = prove = assert = verify
" check:maybe = lemma = assumption = guess = conjecture = hypothesis
" Latin abbrev: SEE https://en.wikipedia.org/wiki/List_of_Latin_abbreviations
" E.G. exampli gratia (~ example given)
" I.E. id est (~ in especial, effectively)
" I.A. inter alia (~ among other things)
" VIZ. videlicet (~ precisely: implies (near) completeness)
" N.B. nota bene (~ pay attention, take notice) == NOTE, ATT

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
  if exists('w:everywhere_matches')| return |en
  for [k,c,g,p] in a:patts
    " ALT:BAD: '\v<(OR)>[:?!*.=]*'
    call matchadd('Notch'. k, '\v%(^|.*!|\A@1<=)%('.p.')%(!.*|[:?*.=]+|\A@=|$)', -1)
  endfor
  let w:everywhere_matches = 1
endfunction


function! s:everywhere_init_once(force)
  if !a:force && exists('w:everywhere_notches') && w:everywhere_notches| return |en
  call s:everywhere_define(s:patterns)
  call s:everywhere_matches(s:patterns)
  let w:everywhere_notches = 1
endfunction


function! s:everywhere_enable(mode)
  let g:everywhere_activated = a:mode
  call s:everywhere_init_once(0)
  augroup EverywhereNotches
    autocmd!
    if g:everywhere_activated
      au WinEnter * call s:everywhere_init_once(0)
      " BAD: appended multiple times on each opened buffer
      "   DEBUG: :echo getmatches()
      " au Syntax * call s:everywhere_matches(s:patterns)
      " au ColorScheme * call s:everywhere_define(s:patterns)
    endif
  augroup END
endfunction


let g:everywhere_activated = 1
call s:everywhere_enable(1)
" autocmd WinEnter,VimEnter * call s:everywhere_enable(1)

command! -bar -bang -nargs=0 EverywhereNotchesList
  \ call s:everywhere_print(s:patterns)|syntax off|syntax on

"" BUG: can't toggle notches -- w/o "au Syntax" they aren't triggered anymore
" command! -bar -bang -nargs=0 EverywhereNotchesToggle
"   \ syntax off|call s:everywhere_enable(!g:everywhere_activated)|syntax on
" nnoremap <unique> [Toggle]T :EverywhereNotchesToggle<CR>
