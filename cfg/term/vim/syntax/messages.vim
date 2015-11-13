"" Fix STB logs highlighting, add commentary ability:

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

source $VIMRUNTIME/syntax/messages.vim
" FIXED one-digit date and indented lines
syn clear messagesBegin
syn match messagesBegin display nextgroup=messagesDate,messagesDateRFC3339
      \ /^\s*\zs/
syn clear messagesDate
syn match messagesDate  display contained nextgroup=messagesHour
      \ /\a\a\a \([ 0-9]\)\=\d */

syn match messagesComment /[\t#].*$/ display
hi def link messagesComment Comment

syn match messagesPath /\v[\t#]*\S+:\d+$/ display
hi def link messagesPath Underlined
