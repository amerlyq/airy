Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v "AmerDemons" /t REG_SZ /d "%CD%\DelayLaunch.exe"
pause
rem REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v "AmerDemons" /f


rem CopyLinks to autoload folder
rem set dau="C:\Users\Amer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"