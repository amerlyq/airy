" TODO?
"" Highlight pidgin logs:
function! PidginHL()
  syntax match pidginMe '^([^)]\+) me:'
  syntax match pidginOther '\v^\([^)]+\)( me)@!.*:'

  highlight link pidginMe Type
  highlight link pidginOther Identifier
endfunction
command! -bar -nargs=0 PidginHL call PidginHL()
