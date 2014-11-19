" Ensure that vim uses the correct shell for command substitution
if has('win32') || has('win64')
    " Is there sense let use git-msys under git instead of cmd.exe?
    set shell=cmd.exe
else
    set shell=/bin/sh "bash
endif

set confirm       " ask user before aborting an action
set history=9999  " remember last commands & searche patts

