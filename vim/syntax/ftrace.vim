"" Syntax highlight for ftrace.vim
if version < 600
  syntax clear
elseif exists('b:current_syntax')
  finish  " EXPL: allows to redefine this syntax by user's 'syntax/ag.vim'
endif

syntax case match       " Individual ignorecase done by '\c' prefix (performance)
syntax sync clear
syntax sync minlines=1

let s:colors = [
  \ '#268bd2',
  \ '#2aa198',
  \ '#859900',
  \ '#c5a900',
  \ '#dd6616',
  \ '#dc322f',
  \ '#d33682',
  \ '#6c71c4',
  \ '#586e75',
  \ ]

fun! s:_indent(i)
  let ind = '%(\t| {'.&ts.'})'
  let p = '^'
  let p .= '%('.ind.'{1})'
  let p .= '%('.ind.'{'.len(s:colors).'}){-}'
  let p .= '%('.ind .'{'. a:i .'})' . '\ze\S'
  return p
endf

fun! s:_highlight(nm, c, ...)
  if a:c =~ '^#\x\+$'| let c = 'guifg='.a:c |else| let c = a:c |en
  exe 'hi! '. a:nm .' '. c .(a:0<1?'': ' '.a:1)
endf

fun! s:p(_, ...)
  let q = get(a:,1,'/')
  return q.'\v'.escape(a:_,q).q
endf

fun! s:outline(i)
  let nm = 'ftraceOutline'.a:i
  exe 'syn region '.nm.' display keepend excludenl'
    \.' start='.s:p(s:_indent(a:i))
    \.' skip='.s:p('\\\s*$')
    \.' end='.s:p('$')
  call s:_highlight(nm, s:colors[a:i])
endf

for i in range(len(s:colors))
  call s:outline(i)
endfor

" EXPL: must be last line -- set single-loading guard only if no exceptions
let b:current_syntax = 'ftrace'
