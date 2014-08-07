set pth=%CD%
c:
cd %SystemRoot%\syswow64\WindowsPowerShell\v1.0\
powershell.exe -File "%pth%AutoBackUp.ps1"
pause