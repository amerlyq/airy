"" Highlight pidgin logs:

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syn match pidginMe     '^([^)]\+) me:'
syn match pidginOther  '\v^\([^)]+\)( me)@!.*:'

hi def link pidginMe Type
hi def link pidginOther Identifier
