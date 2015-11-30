let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" # Debug                                  {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#c#fold#verbose(...) abort
  if a:0 > 0 | let s:verbose = a:1 | endif
  if s:verbose
    sign define Fold0   text=0  texthl=Identifier
    for i in range(1, 9)
      exe 'sign define Fold'.i.'   text=|'.i.'  texthl=Identifier'
      exe 'sign define Fold'.i.'gt text=>'.i.' texthl=Identifier'
      exe 'sign define Fold'.i.'lt text=<'.i.' texthl=Identifier'
    endfor
  endif
  exe 'sign unplace * buffer='.bufnr('%')
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#c#fold#debug(expr)
  return eval(a:expr)
endfunction

" # Options                                {{{2
" let b/g:fold_options = {
      " \ 'show_if_and_else': 1,
      " \ 'strip_template_argurments': 1,
      " \ 'strip_namespaces': 1,
      " \ 'fold_blank': 1
      " \ }
function! s:opt_show_if_and_else()
  return lh#option#get('fold_options.show_if_and_else', 1)
endfunction
function! s:opt_strip_template_argurments()
  return lh#option#get('fold_options.strip_template_argurments', 1)
endfunction
function! s:opt_strip_namespaces()
  return lh#option#get('fold_options.strip_namespaces', 1)
endfunction
function! s:opt_fold_blank()
  return lh#option#get('fold_options.fold_blank', 1)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#c#fold#expr()               {{{2
" Expectation: with i < j, lh#c#fold#expr(i) is called before lh#c#fold#expr(j)
" This way instead of having something recursive to the extreme, we cache fold
" levels from one call to the other.
" It means sometimes we have to refresh everything with zx/zX
function! lh#c#fold#expr(lnum) abort
  " 0- Resize b:fold_* arrays to have as many lines as the buffer {{{4
  call s:ResizeCache()

  " 1- First obtain the current fold boundaries {{{4
  let where_it_starts = b:fold_data_begin[a:lnum]
  if where_it_starts == 0
    " it's possible the boundaries was never known => compute thems
    let where_it_ends   = s:WhereInstructionEnds(a:lnum)
    let where_it_starts = b:fold_data_begin[a:lnum]
  else
    " Actually, we can't know when text is changed, the where it starts may
    " change
    let where_it_ends = b:fold_data_end[a:lnum]
  endif


  " 2- Then return what must be {{{4
  let instr_start = b:fold_data_instr_begin[a:lnum]
  let instr_lines = getline(instr_start, where_it_ends)
  " TODO: support multiline comments
  call map(instr_lines, "s:CleanLine(v:val)")
  let instr_line = join(instr_lines, '')
  " let incr = len(substitute(instr_line, '[^{]', '', 'g'))
  " let decr = len(substitute(instr_line, '[^}]', '', 'g'))

  " Case: "} catch|else|... {" & "#elif" & "#else" {{{5
  " TODO: use the s:opt_show_if_and_else() option
  " -> We check the next line to see whether it closes something before opening
  "  something new
  if a:lnum < line('$')
    let next_line = getline(a:lnum+1)
    if next_line =~ '}.*{'
      " assert(where_it_ends < a:lnum+1)
      let decr = len(substitute(matchstr(next_line, '^[^{]*'), '[^}]', '', 'g'))
            \ + len(substitute(instr_line, '[^}]', '', 'g'))
      let b:fold_context[a:lnum] = ''
      return s:DecrFoldLevel(a:lnum, decr)
    elseif next_line =~ '^\s*#\s*\(elif\|else\)'
      let decr = 1
            \ + len(substitute(instr_line, '[^}]', '', 'g'))
      return s:DecrFoldLevel(a:lnum, decr)
    endif
  endif

  " The lines to analyze {{{5
  let lines = getline(where_it_starts, where_it_ends)
  let line  = getline(where_it_ends)

  " Case: #include {{{5
  if line =~ '^\s*#\s*include'
    let b:fold_context[a:lnum] = 'include'
    if     b:fold_context[a:lnum-1] == '#if'
      " Override include context
      let b:fold_context[a:lnum] = b:fold_context[a:lnum-1]
      return s:KeepFoldLevel(a:lnum)
    elseif b:fold_context[a:lnum-1] != 'include'
      let b:fold_context[where_it_starts : where_it_ends]
            \ = repeat(['include'], 1 + where_it_ends - where_it_starts)
      return s:IncrFoldLevel(a:lnum, 1)
    endif

    let where_next_ends = s:WhereInstructionEnds(a:lnum+1)
    let next_lines = getline(a:lnum+1, where_next_ends)
    if match(next_lines, '^\s*#\s*include') == -1
      return s:DecrFoldLevel(a:lnum, 1)
    else
      let b:fold_context[where_it_starts : where_next_ends]
            \ = repeat(['include'], 1 + where_next_ends - where_it_starts)
      return s:KeepFoldLevel(a:lnum)
    endif
  elseif b:fold_context[a:lnum] == 'include' && a:lnum == where_it_ends
      return s:DecrFoldLevel(a:lnum, 1)
  endif

  " Clear include context {{{5
  " But maintain #if context and ignore #endif context
  if     b:fold_context[a:lnum-1] == '#if' && b:fold_context[a:lnum] != '#endif'
    let b:fold_context[a:lnum] = b:fold_context[a:lnum-1]
  elseif b:fold_context[a:lnum] != '#endif'
    let b:fold_context[a:lnum] = ''
  endif

  " Case: Opening things ? {{{5
  " The foldlevel increase can be done only at the start of the instruction
  if a:lnum == where_it_starts
    if line =~ '^\s*#\s*if'
      let b:fold_context[a:lnum] = '#if'
      return s:IncrFoldLevel(a:lnum, 1)
    endif
  elseif line =~ '{[^}]*$'
    " Case: opening, but started earlier
    " -> already opened -> keep fold level
    return s:KeepFoldLevel(a:lnum)
  endif

  " Case: "#else", "#elif", "#endif" {{{5
  if line =~ '^\s*#\s*\(else\|elif\)'
    return s:IncrFoldLevel(a:lnum, 1)
  elseif  match(lines, '^\s*#\s*endif') >= 0
    if a:lnum == where_it_ends
      let b:fold_context[a:lnum] = '#endif'
      return s:DecrFoldLevel(a:lnum, 1)
    else
      " Register where the #endif ends
      let b:fold_context[where_it_starts : where_it_ends]
            \ = repeat(['#endif'], 1 + where_it_ends - where_it_starts)
    endif
  endif
  if b:fold_context[a:lnum] == '#endif' && a:lnum == where_it_ends
      return s:DecrFoldLevel(a:lnum, 1)
  endif

  " Case: "} ... {" -> "{"  // the return of the s:opt_show_if_and_else() {{{5
  " TODO: support multiline comments
  call map(instr_lines, "substitute(v:val, '^[^{]*}\\ze.*{', '', '')")

  let line = join(instr_lines, '')
  let incr = len(substitute(line, '[^{]', '', 'g'))
  let decr = len(substitute(line, '[^}]', '', 'g'))

  if incr > decr
    return s:IncrFoldLevel(a:lnum, incr-decr)
  elseif decr > incr
    if a:lnum != where_it_ends
      " Wait till the last moment!
      return s:KeepFoldLevel(a:lnum)
    else
      return s:DecrFoldLevel(a:lnum, decr-incr)
    endif
  else
    " This is where we can detect instructions spawning on several lines
    if line =~ '{.*}'
      " first case: oneliner that cannot be folded => we left it as it is
      if     a:lnum == instr_start && a:lnum == where_it_ends | return s:KeepFoldLevel(a:lnum)
      elseif a:lnum == instr_start                            | return s:IncrFoldLevel(a:lnum, 1)
      elseif a:lnum == where_it_ends                          | return s:DecrFoldLevel(a:lnum, 1) " Note: this case cannot happen
      endif
    endif
    return s:KeepFoldLevel(a:lnum)
  endif
endfunction

" Function: lh#c#fold#text()               {{{2
function! CFoldText_(lnum) abort
  let lnum = s:NextNonCommentNonBlank(a:lnum, s:opt_fold_blank())

  " Case: #include  {{{3
  if b:fold_context[a:lnum] == 'include'
    let includes = []
    let lastline = line('$')
    while lnum <= lastline && b:fold_context[lnum] == 'include'
      let includes += [matchstr(getline(lnum), '["<]\zs.*\ze[">]')]
      let lnum = s:NextNonCommentNonBlank(lnum+1, s:opt_fold_blank())
    endwhile
    return '#include '.join(includes, ' ')
  endif

  " Case: #if & co {{{3
  " No need: What follows does the work

  " Loop for all the lines in the fold                {{{3
  let ts = s:Build_ts()
  let line = ''
  let in_macro_ctx = 0

  let lastline = b:fold_data_end[a:lnum]
  while lnum <= lastline
    let current = getline(lnum)
    " Foldmarks will get ignored
    let current = substitute(current, '{\{3}\d\=.*$', '', 'g')
    " Get rid of C comments
    let current = substitute(current, '/\*.*\*/', '', 'g')

    if current =~ '^#\s*\(if\|elif\).*\\$'
      let in_macro_ctx = 1
      let current = substitute(current, '\s*\\$', '', '')
      let break = 0
      let lastline = line('$')
    elseif in_macro_ctx
      let in_macro_ctx = !empty(current) && current[-1] == '\\'
      let current = substitute(current, '\s*\\$', '', '')
      let break = ! in_macro_ctx

    elseif current =~ '[^:]:[^:]'
      " class XXX : ancestor
      let current = substitute(current, '\([^:]\):[^:].*$', '\1', 'g')
      let break = 1
    elseif current =~ '{\s*$'
      " '  } else {'
      let current = substitute(current, '^\(\s*\)}\s*', '\1', 'g')
      let current = substitute(current, '{\s*$', '', 'g')
      let break = 1
    else
      let break = 0
    endif
    if empty(line)
      " preserve indention: substitute leading tabs by spaces
      let leading_spaces = matchstr(current, '^\s*')
      let leading_spaces = substitute(leading_spaces, "\t", ts, 'g')
    endif

    " remove leading and trailing white spaces
    let current = matchstr(current, '^\s*\zs.\{-}\ze\s*$')
    " let current = substitute(current, '^\s*', '', 'g')
    " Manual join(), line by line
    if !empty(line) && current !~ '^\s*$' " add a separator
      let line .= ' '
    endif
    let line .= current
    if break
      break
    endif
    " Goto next line
    let lnum = s:NextNonCommentNonBlank(lnum + 1, s:opt_fold_blank())
  endwhile

  " Strip whatever follows "case xxx:" and "default:" {{{3
  let line = substitute(line,
        \ '^\(\s*\%(case\s\+.\{-}[^:]:\_[^:]\|default\s*:\)\).*', '\1', 'g')

  " Strip spaces within parenthesis                   {{{3
  let line = substitute(line, '\s\{2,}', ' ', 'g')
  let line = substitute(line, '(\zs \| \ze)', '', 'g')

  " Strip namespaces
  if s:opt_strip_namespaces()
    let line = substitute(line, '\<\k\+::', '', 'g')
  endif

  " Add Indentation                                   {{{3
  let line = leading_spaces . line

  " Strip template parameters                         {{{3
  if strlen(line) > (winwidth(winnr()) - &foldcolumn)
        \ && s:opt_strip_template_argurments() && line =~ '\s*template\s*<'
    let c0 = stridx(line, '<') + 1 | let lvl = 1
    let c = c0
    while c > 0
      let c = match(line, '[<>]', c+1)
      if     line[c] == '<'
        let lvl += 1
      elseif line[c] == '>'
        if lvl == 1 | break | endif
        let lvl -= 1
      endif
    endwhile
    " TODO: doesn't work with template specialization
    let line = strpart(line, 0, c0) . '...' . strpart(line, c)
  endif

  " Return the result                                 {{{3
  return substitute(line, "\t", ' ', 'g')
  " let lines = v:folddashes . '[' . (v:foldend - v:foldstart + 1) . ']'
  " let lines .= repeat(' ', 10 - strlen(lines))
  " return lines . line
endfunction

function! lh#c#fold#text() abort
  " return getline(v:foldstart) " When there is a bug, use this one
  return CFoldText_(v:foldstart)
endfunction

" Function: lh#c#fold#clear(cmd)           {{{2
" b:fold_data_begin: Block of non empty lines before the instruction
"                    New line => new block
"                    TODO: merge several comment blocks ?
" b:fold_data_end:   Will contain all empty lines  that follow
"                    TODO: special case: do {...} while ();
"
" + special case: #includes
function! lh#c#fold#clear(cmd) abort
  call lh#c#fold#verbose(s:verbose) " clear signs
  let b:fold_data_begin       = repeat([0], 1+line('$'))
  let b:fold_data_end         = copy(b:fold_data_begin)
  let b:fold_data_instr_begin = copy(b:fold_data_begin)
  let b:fold_data_instr_end   = copy(b:fold_data_begin)
  let b:fold_levels           = copy(b:fold_data_begin)
  let b:fold_context          = repeat([''], 1+line('$'))
  exe 'normal! '.a:cmd
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: s:ResizeCache()                {{{2
function! s:ResizeCache() abort
  let missing = line('$') - len(b:fold_levels) + 1
  if missing > 0
    let to_be_appended = repeat([0], missing)
    let b:fold_levels           += to_be_appended
    let b:fold_data_begin       += to_be_appended
    let b:fold_data_end         += to_be_appended
    let b:fold_data_instr_begin += to_be_appended
    let b:fold_data_instr_end   += to_be_appended
    let b:fold_context          += repeat([''], missing)
  endif
  " @post len(*) == line('$') + 1
endfunction

" Function: s:CleanLine(line)              {{{2
" clean from comments
" TODO: merge with similar functions in lh-cpp and lh-dev
function! s:CleanLine(line) abort
  " 1- remove strings
  let line = substitute(a:line, '".\{-}[^\\]"', '', 'g')
  " 2- remove C Comments
  let line = substitute(line, '/\*.\{-}\*/', '', 'g')
  " 3- remove C++ Comments
  let line = substitute(line, '//.*', '', 'g')
  return line
endfunction

" Function: s:WhereInstructionEnds()       {{{2
" Given a line number, search for something that indicates the end of a
" instruction => ; , {, }
" TODO: Handle special case: "do { ... }\nwhile()\n;"
function! s:WhereInstructionEnds(lnum) abort
  let last_line = line('$')
  let lnum = a:lnum
  let last = lnum
  while lnum <= last_line
    "" Where the instruction started
    " let b:fold_data_begin[lnum] = a:lnum
    let line = getline(lnum)
    if line =~ '^\s*$'
      break
    else
      let line = s:CleanLine(line)
      if line =~ '[{}]\|^\s*#\|^\s*\(public\|private\|protected\):\|;\s*$'
        let last = lnum
        while lnum < last_line && getline(lnum+1) =~ '^\s*$'
          let lnum += 1
        endwhile
        break
      endif
    endif
    let lnum += 1
  endwhile

  " assert(lnum <= last_line)
  let b:fold_data_instr_begin[(a:lnum):lnum] = map(b:fold_data_instr_begin[(a:lnum):lnum], 'min([v:val==0 ? (a:lnum) : v:val, a:lnum])')
  " let b:fold_data_instr_end[(a:lnum):last]   = repeat([last], last-a:lnum+1)
  let b:fold_data_begin[(a:lnum):lnum]       = repeat([a:lnum], lnum-a:lnum+1)
  let b:fold_data_end[(a:lnum):lnum]         = repeat([lnum], lnum-a:lnum+1)

  return lnum
endfunction

" Function: s:IsACommentLine(lnum)         {{{2
function! s:IsACommentLine(lnum, or_blank) abort
  let line = getline(a:lnum)
  if line =~ '^\s*//'. (a:or_blank ? '\|^\s*$' : '')
    " C++ comment line / empty line => continue
    return 1
  elseif line =~ '\S.*\(//\|/\*.\+\*/\)'
    " Not a comment line => break
    return 0
  else
    let id = synIDattr(synID(a:lnum, strlen(line)-1, 0), 'name')
    return id =~? 'comment\|doxygen'
  endif
endfunction

" Function: s:NextNonCommentNonBlank(lnum) {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank) abort
  let lnum = a:lnum
  let lastline = line('$')
  while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
    let lnum += 1
  endwhile
  return lnum
endfunction

" Function: s:Build_ts()                   {{{2
function! s:Build_ts() abort
  if !exists('s:ts_d') || (s:ts_d != &ts)
    let s:ts = repeat(' ', &ts)
    let s:ts_d = &ts
  endif
  return s:ts
endfunction

" Function: s:ShowInstrBegin()             {{{2
function! s:ShowInstrBegin() abort
  silent sign define Fold   text=~~ texthl=Identifier

  let bufnr = bufnr('%')
  silent! exe 'sign unplace * buffer='.bufnr
  let boi = lh#list#unique_sort(values(b:fold_data_begin))
  for l in boi
    silent exe 'sign place '.l.' line='.l.' name=Fold buffer='.bufnr
  endfor
endfunction

" Function: s:IncrFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:IncrFoldLevel(lnum, nb) abort
  let b:fold_levels[a:lnum] = b:fold_levels[a:lnum-1] + a:nb
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_levels[a:lnum].'gt buffer='.bufnr('%')
  endif
  return '>'.b:fold_levels[a:lnum]
endfunction

" Function: s:DecrFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:DecrFoldLevel(lnum, nb) abort
  let b:fold_levels[a:lnum] =  max([b:fold_levels[a:lnum-1]- a:nb, 0])
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.(b:fold_levels[a:lnum]+1).'lt buffer='.bufnr('%')
  endif
  return '<'.(b:fold_levels[a:lnum]+1)
endfunction

" Function: s:KeepFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:KeepFoldLevel(lnum) abort
  let b:fold_levels[a:lnum] = b:fold_levels[a:lnum-1]
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_levels[a:lnum].' buffer='.bufnr('%')
  endif
  return b:fold_levels[a:lnum]
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
