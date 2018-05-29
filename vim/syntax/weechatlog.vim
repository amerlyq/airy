"" Highlight weechat logs

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn match weeBegin display nextgroup=weeDate /^\s*\zs/
syn match weeDate  display contained nextgroup=weeTime /\S\+\s/
syn match weeTime  display contained nextgroup=weeNick /\S\+\t/
syn match weeNick  display contained nextgroup=weeBody /\S\+\t/
syn match weeBody  display contained /.*/

hi def link weeDate Type
hi def link weeTime Identifier
hi def link weeNick Statement
hi def link weeBody Normal

let b:current_syntax = "weechatlog"

let &cpo = s:cpo_save
unlet s:cpo_save
