Set Path=%~dp0
Set Path=%Path:~0,-1%
c:
cd %SystemRoot%\syswow64\WindowsPowerShell\v1.0
powershell_ise.exe -File "%Path%JobBackUp.ps1"
pause