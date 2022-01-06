@echo off

:This little bit just cds to the directoty contianing this file
%~d0
cd %~dp0


skse_loader.exe

:this ping command is used as a timer - fukken dos not havin a real sleep command
ping -n 3 127.0.0.1 > nul
:This line just make it call in the background
START /B CMD /C CALL SBW.exe

set mouseon=true

:while
ping -n 2 127.0.0.1 > nul

:set wintitle to currently selected window title
for /f "delims=" %%a in ('getwindowtitle.exe') do @set wintitle=%%a

if "%wintitle%"=="Skyrim" (
	:Switched into skyrim - turn off mouse
	if "%mouseon%"=="true" (
		:This program will poll a file, and exit when its deleted
		START /B CMD /C CALL mouse.exe
		echo mouse off
		set mouseon=false
	)
) else (
	:Switched out of skyrim - turn on mouse
	if "%mouseon%"=="false" (
		:deleting this file makes mouse.exe exit, and restore cursor
		del mouse.lck
		echo mouse on
		set mouseon=true
	)
)

:Keep looping while skyrim is running
tasklist /FI "IMAGENAME eq TESV.exe" 2>NUL | find /I /N "TESV.exe">NUL
if "%ERRORLEVEL%"=="0" goto while

echo exiting...


:Make sure mouse cursor gets unhidden
if "%mouseon%"=="false" (
		del mouse.lck
		echo mouse on

)
:Make sure SBW dies
taskkill /IM "SBW.exe">NUL 2>&1
