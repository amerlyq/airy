@echo off
rem chcp 1251
rem <Включаем поддержку отложенной инициализации переменных  !переменная!>
setlocal enabledelayedexpansion
rem -ri0:10 //приоритет и задержка в милисекундах
rem // Необходим механизм создания папок в Форе с проверкой на существование, если задаётся папка Энного вложения.

rem Если вывод уже был перенаправлен в файл.
rem if "%STDOUT_REDIRECTED%" == yes goto :Archiving

rem // Глюк - переименовало папку с именем backup. Необходимо отлавливать папка/файл.
set "ARCHNAME=backup"
set "ARCHNAMEOLD=backup_old.rar"

rem <Files and Dirs>
set "FILEADD=files_append.txt"
set "FILESKIP=files_skip.txt"

rem <Working dirs>
set "WORKDISK=k:"
set "WORKDIR=\Back-ups\"
set "TMPDIR=%WORKDISK%\"

rem <Log files>
set "LOGSTD=logstd.log"
set "LOGMN=log.log"
set "LOGER=log_errors.log"
set "LOGCA=log_created_archives.log"
set "LOGPF=log_processed_files.log"

rem <Rar Options>
set UNCOMPRESSED=*.rar;*.zip;*.7z;*.msi;*.cab;*.wim;*.ipa;*.jpg;*.jpeg;*.gif;*.pdf;*.djvu;*.mp3;*.mp4;*.m4v;*.m4a;*.m4b;*.wmv;*.docx
set EXCLUDED=-x@%FILESKIP%
rem -x*.sdf -x*\ipch\
set LOGTO=-ilog=%LOGER% -logapu=%LOGCA% -logfpu=%LOGPF%
set RARKEYS=-scal -dh -m2 -w%TMPDIR% -ms%UNCOMPRESSED% -rr4p %LOGTO% -r -t -as -u
rem -v20m // Бить на куски по 20 метров


@%WORKDISK%
@cd %WORKDIR%

rem // В меню добавить выбор "с - копирование на носители" - жёсткий диск итп. После чего открывается диалог выбора буквы диска, при котором надо либо ввести букву, либо выбрать одну из перечисленных. Так же, можно это оформить как дополнительную опцию - копировать на диск по завершению операции (z). Может имеет смысл заменить все буквы на цифры?

:CHOICE
set /P CHOICE=Create backup (b)? Update archive (u)? Quit (q)? :
 if '%CHOICE%'=='b' goto :Create_backup
 if '%CHOICE%'=='u' goto :Archiving
 if '%CHOICE%'=='q' goto :Exit
 if '%CHOICE%'==''  goto :Exit
 set CHOICE=
goto :CHOICE

:Create_backup
if exist %ARCHNAMEOLD% del %ARCHNAMEOLD%
if exist %ARCHNAME% ren %ARCHNAME% %ARCHNAMEOLD%

rem copy %DIRNAME%\%FILENAME%.rar %COPYTO%\%DIRNAME%

:Archiving
rem if "%STDOUT_REDIRECTED%" == "" (
rem     set STDOUT_REDIRECTED=yes
rem     cmd.exe /c %0 %* >%LOGSTD%
rem     exit /b %ERRORLEVEL%
rem )

echo %DATE% ^| %TIME% ^| 1. Start procedures. >> %LOGMN%

if exist "%LOGER%" del "%LOGER%"
if exist "%LOGCA%" del "%LOGCA%"
if exist "%LOGPF%" del "%LOGPF%"

echo %DATE% ^| %TIME% ^| 2. Compressing files. >> %LOGMN%

rem на самом деле здесь должна идти упаковка отдельно по разным архивам.


@"C:\Program Files\WinRAR\Rar" a %RARKEYS% %EXCLUDED% %ARCHNAME% @%FILEADD%

if exist %ARCHNAME%.part01.rar ( @"C:\Program Files\WinRAR\Rar" rv14p %ARCHNAME%.part01.rar )

echo %DATE% ^| %TIME% ^| 3. Work is done. >> %LOGMN%
echo ------------------------------------------------ >> %LOGMN%
pause

:Exit
