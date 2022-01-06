@echo off

if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
 :over1
 
if exist "keyinp.obj" del "keyinp.obj"
if exist "keyinp.exe" del "keyinp.exe"

\masm32\bin\ml /c /coff "keyinp.asm"
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS "keyinp.obj" rsrc.res
 if errorlevel 1 goto errlink

dir "keyinp.*"
goto TheEnd

:nores
 \masm32\bin\Link /SUBSYSTEM:WINDOWS "keyinp.obj"
 if errorlevel 1 goto errlink
dir "keyinp.*"
goto TheEnd

:errlink
 echo _
echo Link error
goto TheEnd

:errasm
 echo _
echo Assembly Error
goto TheEnd

:TheEnd
 
pause
