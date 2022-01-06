@Echo off

TASKKILL /F /IM LConfig.exe /T
TASKKILL /F /IM LouderIt.exe /T

ping -n 5 -w 1 127.0.0.1 > nul

DEL /Q "%USERPROFILE%\Главное меню\Программы\Утилиты\LouderIt - Volume Control.lnk"

REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Volumecontrol2" /f
REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f /v "louderit.exe"

REGEDIT /S "%programfiles%\volumecontrol2\vol_on.reg"

cd ..
rmdir /S /Q "%ProgramFiles%\Volumecontrol2"


