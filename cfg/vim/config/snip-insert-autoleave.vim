"" automatically leave insert mode after 'updatetime' milliseconds of inaction
" au CursorHoldI * stopinsert
"" set 'updatetime' to 2 seconds when in insert mode, and restore back on leave
" au InsertEnter * let updaterestore=&updatetime | set updatetime=3000
" au InsertLeave * let &updatetime=updaterestore



