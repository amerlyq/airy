" SPDX-FileCopyrightText: 2020 Dmytro Kolomoiets <amerlyq@gmail.com>
" SPDX-License-Identifier: GPL-3.0-only
" SPDX-PackageName: vim-audit-events
" SPDX-PackageSummary: SUM: log user activity events for global audit ⌇⡟⢇⠚⣒
if &cp||exists('g:loaded_auditevs')|finish|else|let g:loaded_auditevs=1|endif

" CASE: detect time of my last activity on PC for time-tracking
" CASE: add xtrefs to tasks and info pieces post-factum after several hours
"   BET? auto-insert xtrefs immediately on save
"     i.e. by {extract+parse+annotate} undotree() diff between two last saves
"   ALT(manually): get last edited file from ~/.cache/vim/{undo-tree,stay-view,neomru}
"     >> and then manually use DFL :UndotreeShow to find out last edits time

let s:d_audit = '/@/audit/' . hostname() . '/vim'

" FIXME: only run if daemon is running and session is started => ERR otherwise
" systemctl --user is-active lttng-sessiond &>/dev/null
if executable('r.lttng')
  let g:auditev_lttng = 1
else
  let g:auditev_lttng = 0
end


function! s:SaveEditEvent()
  " NOTE: store in git repo on XFS partition (use it for ZSH/BASH history too)
  " ALT:BAD: ~/aura/items/vim/
  let dst = s:d_audit .'/'. strftime('%Y/%Y-%m-%d')
  let d_dst = fnamemodify(dst, ':h')
  if !isdirectory(d_dst)| call mkdir(d_dst, 'p', 0700) |en

  " ALT:USE: = undotree().time_cur
  " let ts = strftime('%s')
  let ts = strftime('%Y-%m-%d %H:%M:%S%z')

  " TRY: get line-span of edits from last save .instead-of. cursor position
  "   i.e. to estimate size of diff
  " FIND:IDEA: convert undotree() into git-like blame with timestamp per line
  let src = join([expand('%:p'), line('.'), col('.')], ':')

  " USAGE: match by regex moved lines
  " SECU:(permissions): stores pieces of sensitive text into insecure location
  "   BUT? all these original text files are under .git anyway
  " ERR: if lines were deleted instead of added -- we will save wrong preview
  " NOTE: prevent too long lines in history due to e.g. accidental save of one-line .json
  " FIXED: clipping last multibyte character
  "   e.g.ERR: /cache/audit/vim/2020/2020-11-28" [ILLEGAL BYTE in line 92] 607L, 78024C
  let chg = strcharpart(getline('.'), 0, 120)

  let ev = [ts, src, chg]

  " HACK: async send to detached lttng-ust
  " if g:auditev_lttng
  "   let $LTTNG_HOME = s:d_audit .'/lttng'
  "   call jobstart(['r.lttng', 'vim', 'save', src, chg], {'detach': 1})
  " end

  " NOTE: don't fsync() to prevent freeze due to !snapper
  call writefile([join(ev, "\t")], dst, 'aS')
endfunction

command! -bar SaveEditEvent call <SID>SaveEditEvent()
augroup SaveEditEvent
  autocmd!
  if isdirectory(s:d_audit)
    au BufWritePost * SaveEditEvent
  endif
augroup END
