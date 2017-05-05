if !has("gui_running") | finish | endif


" set guicursor+=a:blinkwait0 " disable cursor blink in gvim
"set guiheadroom=0


if !IsWindows()
  noremap <ScrollWheelUp>   <C-Y>
  noremap <ScrollWheelDown> <C-E>
endif


if has("gui_gtk2")
  set guifont=PragmataPro\ 12,DejaVu\ Sans\ Mono\ for\ Powerline\ 11,DejaVu\ Sans\ Mono\ 11
elseif has("x11")
  set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
elseif has("win32") || has("win64")
  set guifont=DejaVu_Sans_Mono_for_Powerline:h11,Courier_New:h12
else
  set guifont=Courier_New:h10:cDEFAULT
  "set guifont=-xos4-terminus-medium-r-normal--14-140-72-72-c-80-iso8859-1
endif
