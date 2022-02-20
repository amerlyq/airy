" ⌇⡞⠶⠽⣌
" SPDX-FileCopyrightText: 2020 Dmytro Kolomoiets <amerlyq@gmail.com>
" SPDX-License-Identifier: GPL-3.0-only
" SPDX-PackageName: vim-notches
" SPDX-PackageSummary: keywords/syntax overlay to annotate comments and notes
"
if &cp||exists('g:loaded_notches')|finish|else|let g:loaded_notches=1|endif
if !has('autocmd') || v:version <= 701 | finish | endif

" EXPL: phonetic abbreviations in cyrillic, etc.
iabbrev  туду:  TODO:
iabbrev  ещвщ:  TODO:

" [_] FAIL: below "ex:" is treated as modeline
let s:patterns = [
  \ ['Err', 196, '#ff2525', 'RED|Qs|RQs?|REQUIRE|ERRs?|ERROR|BUG|REGR%(ESSION)?|XXX|WTF|BAD|FAIL%(ED|URE)?|CRIT%(ICAL)?'],
  \ ['Add',  76, '#5faf00', 'GREN|ADD|NEED|FIND|ALSO|BET%(TER)?|E\.G|e\.g|ADVICE'],
  \ ['Ref',  28, '#00af00', 'SEE|READ|REF%(ERENCE)?|TUT%(ORIAL)?|BLOG|BOOK|LIOR|OV|OVERVIEW'],
  \ ['Rul',  22, '#1f881f', 'RULE?s?|LORE'],
  \ ['Alt', 178, '#dfaf00', 'YELW|ALT|OR|CASE|THINK|IDEA|CHG|RENAME|CALL|CMP|I\.E|i\.e|EXAM%(INE)?|OPTL?|OPTIONAL'],
  \ ['Dev',  33, '#0087ff', 'BLUE|DEV%(ELOP)?|CFG|ENH%(ANCE)?|HACK|NICE|RFC|SEP%(ARATE)?|SPL%(IT)?|DECI%(DE)?'],
  \ ['Tbd', 169, '#ff5faf', 'PINK|TODO|CHECK|TRY|MOVE|NOT|REQ%(UEST)?|MAYBE|WAIT%(ING)?'],
  \ ['Inf',  38, '#00afdf', 'CYAN|INFO?|SRC|VARs?|VIZ|ALGO?s?|SEQ%(UENCE)?|HYPO?|CONTR?|CONTRACT|IMPL|ARCH|PERF%(ORMANCE)?|TALK|SECU%(RE|RITY)?|RELI%(ABILITY)?|RELY|MMAP'],
  \ ['Fix', 202, '#ff5f00', 'ORNG|BUT|DONT|TBD|WiP|WIP|FIX|FIXME|FIXUP|WARN%(ING)?|ATTN?|ATTENTION|REM%(OVE)?|OPTS|OPTIONS|BLK|BLOCK|BLOCKED|BlockedBy'],
  \ ['Did', 243, '#767676', 'GREY|DONE|FIXED|WKRND|TEMP%(ORARY)?|UNUSED|OBSOL%(ETE)?|DEPR%(ECATED)?|DSBLD|DISABLED|TL;DR|FORMAT|FMT'],
  \ ['Sem', 163, '#df40af', 'ex:|SEIZE|BUMP|EVOL?|EVOLVE|EVOLUTION'],
  \ ['Hdr',  27, '#004fff', 'OFFL?|OFCL|OFFICIAL|DRAW|WFs?|WORKFLOW|PRIA|PRIOR_ART|FUT|FUTURE|RE|REV-ENG|REVL|REVEAL|XLR|EXPLORE'],
  \ ['Msg',  62, '#5f5fdf', 'PURP|NB|NOTE|USE|DEMO|USAGE|DFL|DEFAULT|STD|SUM%(MARY)?|DEBUG|I\.A|i\.a|DEP[sS]?|DEPENDS'],
  \ ['Unq', 188, '#dfdfdf', 'THEO'],
  \ ['Com', 101, '#958e68', 'EXPL|EXPLAIN|COS|BECAUSE|AGAIN'],
  \]

function! s:everywhere_print(patts)
  tabnew
  setl buftype=nofile bufhidden=wipe nobuflisted
  for [k,c,g,p] in a:patts
    call append(line('.'), k .': '. p)
  endfor
endfunction


function! s:everywhere_define(patts)
  let locals = 'term=bold cterm=bold gui=bold'
  " CHG: use fixed syntax file -- primary hi "notchColor{Red,…}" and linked hi "nou<Worflow><State>"
  for [k,c,g,p] in a:patts  "term=bold,underline guifg=#E01B1B
    exec printf('hi! Notch%s %s ctermfg=%s guifg=%s', k, locals, c, g)
  endfor
endfunction


function! s:everywhere_matches(patts)
  if exists('w:everywhere_matches')| return |en
  for [k,c,g,p] in a:patts
    " ALT:BAD: '\v<(OR)>[:?!*.=]*'
    call matchadd('Notch'. k, '\v%(^|.*!|\A@1<=)%('.p.')%(!.*|[:?*.=~]+|\A@=|$)', -1)
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
