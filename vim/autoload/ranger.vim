" @license MIT, (c) amerlyq, 2017

" BUG:(neovim -> ranger -> nvr -> neovim): keeps old copy of ranger running
"   => resets cursor position on BufFocus or BufWrite

""" Options {{{1
let s:ranger_opencmd = 'edit'     " Edit first
let s:ranger_restcmd = 'argadd'   " Add remaining
let s:ranger_chooser = 'preview'  " VIZ. inplace, new, preview
let s:ranger_viewcmd = 'tabnew'   " VIZ. new, enew, vnew, tabnew
let s:ranger_viewopts = 'setl wfw wfh bt=nofile bh=wipe'  " TEMP:REM: nobl
let s:ranger_rangercmd = ''       " Execute in ranger
let s:ranger_rangerexe = 'ranger' " Cmd name or path to ranger
let s:ranger_rangertabs = []      " Dirs to always open in other tabs

" ENH: executable('ranger') ? : 'ranger#error'
" RFC: vim8 has jobstart, neovim gui has embedded term
"   -> instead of checking prg BET fallback by _func_impl available
let s:ranger_mode = 'ranger#' . (has('gui_running') ? 'in_xorg' :
  \ has('nvim') ? 'in_termopen' : 'in_shell')

let s:_recentcwds = []            " Recent cwd dirs of first file


" WARN:BAD: don't use inside job callback -- 'b:' may be fetched wrong
fun! ranger#cfg(nm)
  let k = 'ranger_'.a:nm
  return get(b:, k, get(g:, k, get(s:, k)))
endf


""" General {{{1
fun! s:getpos()
  return {'buf': bufnr(''), 'tab': tabpagenr(), 'win': winnr()}
endf


" ALT:(abort -- if no errmsg): try| ... |catch| echoerr v:exception |endtry
fun! ranger#open_list(opts) abort
  let f = a:opts.tempname
  if !filereadable(f)| return |en
  let pathes = readfile(f)
  sil! call delete(f)

  " ATT: filter-out directories to prevent recursion
  call filter(pathes, '!isdirectory(v:val)')
  if empty(pathes)| return |en

  " BAD: if multiselect in 'flat' view => cwd != dirname of 1st file
  "   THINK: how to pass ranger's cwd back ?
  "   TRY always pass as first line of tempfile ?
  "     => so even simply moving by ranger w/o choosing file store last cwd in history
  "   IDEA: use ranger to change cwd/lcwd for vim
  let s:_recentcwds = [fnamemodify(pathes[0], ':p:h')] + s:_recentcwds[:-2]
  exe a:opts.opencmd.' '.fnameescape(pathes[0])
  "Need for VIM-only? filetype detect
  for p in pathes[1:]
    exe a:opts.restcmd.' '.fnameescape(p)
    "Need for VIM-only? if a:opts.restcmd != 'argadd'| filetype detect |en
  endfor
endf


""" Providers {{{1
" TRY:
" ALT:BET: prepend $TERMCMD to rangerexe
fun! ranger#in_xorg(cmd, opts)
  let cmd = join(map(a:cmd, 'shellescape(v:val)'), ' ')
  sil exe '!'.expand($TERMCMD).' '. escape(cmd, '%#') | redraw!
  call ranger#open_list(a:opts)
endf

" TRY:
fun! ranger#in_shell(cmd, opts)
  let cmd = join(map(a:cmd, 'shellescape(v:val)'), ' ')
  sil exe '!' . escape(cmd, '%#') | redraw!
  call ranger#open_list(a:opts)
endf

" current tab/win
"   -- directly in that same win
"     => close buf of ranger
"   -- in new preview and return
"     => close win/tab
"     => close buf of ranger
"     => try to return to ppos
" open preview in new tab/win
"   -- and open files in the same one
"     => close buf of ranger
" => => open files in that new one

fun! ranger#in_termopen(cmd, opts)
  exe ranger#cfg('viewcmd')
  exe ranger#cfg('viewopts')
  let a:opts.termfocus = s:getpos()

  fun! a:opts.on_exit(jid, code, ...) dict abort
    let c = s:getpos()
    let p = self.prevfocus
    let t = self.termfocus
    " echom string(c).':'.string(p).':'.string(t)

    if ranger#cfg('termfocus') == 'preview'
      " ATT: 'bd <num>' also closes win/tab if bufnr!=num
      " sil exe t.buf .'bdelete '
      " ATT: term can be closed only by :close, :bd isn't working properly ?
      "   https://vi.stackexchange.com/questions/10292/how-to-close-and-and-delete-terminal-buffer-if-programs-exited
      exe t.win .'close'

      if c.buf == t.buf
        exe p.tab .'tabnext'
        exe p.win .'wincmd w'
        " ALT: exe p.buf .'bnext'
        exe p.buf .'buffer'
      endif
    endif

    exe 'sil! '. c.buf .'bdelete!'

    call ranger#open_list(self)
    redraw!  " CHECK: if needed
  endf

  let jid = termopen(a:cmd, a:opts)
  if jid <= 0 | echoerr 'Err: termopen -> '.jid | return 1 |en
  startinsert
endf


fun! ranger#do(paths, ...) abort
  " TODO: set 'name' for buf/tab header
  let opts = {'name': 'Ranger', 'tempname': tempname()
    \, 'opencmd': get(a:, 1, ranger#cfg('opencmd'))
    \, 'restcmd': get(a:, 2, ranger#cfg('restcmd'))
    \, 'prevfocus': s:getpos()
    \}

  " MAYBE:OLD: jobstart() need string instead of list
  let cmd = ['env', 'EDITOR=nvr', ranger#cfg('rangerexe')]
  let cmd += ['--choosefiles=' . opts.tempname]
  let _ = ranger#cfg('rangercmd') | if !empty(_)| let cmd += ['--cmd='._] |en
  let _ = get(a:paths, 0) | if !empty(_)| let cmd +=  ['--selectfile='._] |en

  " NOTE: convert filepath into its dirname or filter-out if not found
  for p in a:paths[1:]
    if !isdirectory(p)| let p = fnamemodify(p, ':p:h') |en
    if isdirectory(p)| let cmd+=[p] |en
  endfor

  call call(ranger#cfg('mode'), [cmd, opts])
endf


" NOTE: if typeof(arg1)=dir, DFL open dir, OR <bang>! only selects it
" NOTE: <bang>! empty results in agenda of tabs
" NOTE: multiple args = multiple tabs
fun! ranger#command(bang, ...)
  if a:0 > 0
    let paths = a:bang ? [''] : []
    for a in a:000| let paths += [expand(a)] |endfor
  elseif a:bang
    let paths = [expand('%:p'), getcwd()]
    let paths += filter(uniq(s:_recentcwds), 'v:val != getcwd()')
  else
    let paths = [expand('%:p')]
  endif
  " THINK: add always or only in agenda mode
  "   => diff cmds/funcs RangerAgenda and RangerChooser
  for a in ranger#cfg('rangertabs')
    if isdirectory(a)| let paths += [t]
    else| exe 'let paths += ['.t.']' |en
  endfor
  call ranger#do(paths)
endf
