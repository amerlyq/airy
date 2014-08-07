@echo off
rem Usage C:\masm32\bin\amer_build.bat $(FILE_NAME) $(CURRENT_DIRECTORY)

set "file_full=%1"
set "file_dir=%2"
rem Удаление расширения в переданном из Нотепада++ имени файла
set "file_name=%file_full:~0,-4%"
set "file=%file_dir%\%file_name%"
set "masm=c:\masm32\bin"
echo "File: %file_dir%\%file_full%"

cd c:
cd %file_dir%

if exist "%file%.obj" del "%file%.obj"
if exist "%file%.exe" del "%file%.exe"

%masm%\ml /c /coff "%file%.asm"
if errorlevel 1 goto errasm

if not exist "%file%.rc" goto next
%masm%\rc "%file%.rc"
%masm%\link /SUBSYSTEM:WINDOWS /LIBPATH:"%masm:~0,-3%lib" "%file%.obj" "%file%.res"
if errorlevel 1 goto errlink
echo Compilation with a file of resources has passed successfully.
goto TheEnd

:next

if not exist rsrc.obj goto nores

%masm%\Link /SUBSYSTEM:WINDOWS /OPT:NOREF "%file%.obj" rsrc.obj
if errorlevel 1 goto errlink

dir "%file%.*"
goto TheEnd

:nores
%masm%\Link /SUBSYSTEM:WINDOWS /OPT:NOREF "%file%.obj"
if errorlevel 1 goto errlink
dir "%file%.*"
goto TheEnd

:errlink
echo _
echo Link error
pause
goto TheEnd

:errasm
echo _
echo Assembly Error
pause
goto TheEnd

:TheEnd

%file%.exe

rem pause
