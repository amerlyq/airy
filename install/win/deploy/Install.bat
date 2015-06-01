
set "USERPOLICY=HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
set "MACHINEPOLICY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"


:: Disks autorun disable
REG ADD "%USERPOLICY%\Explorer" /V NoDriveTypeAutorun /T REG_DWORD /D 0xFF /F

:: Disable/enable lock workstation
::REG ADD "%USERPOLICY%\System" /V DisableLockWorkstation /T REG_DWORD /D 0x1 /F
::REG DELETE "%USERPOLICY%\System" /V DisableLockWorkstation /F

:: Disable/enable Blackaning only, UAC
REG ADD "%MACHINEPOLICY%\System" /V PromptOnSecureDesktop /T REG_DWORD /D 0x0 /F
:: However temporary complete disabling while installing bunch on software (after OS reinstall) has sense too.
REG ADD "%MACHINEPOLICY%\System" /V EnableLUA /T REG_DWORD /D 0x0 /F
::REG ADD "%MACHINEPOLICY%\System" /V EnableLUA /T REG_DWORD /D 0x1 /F


:: To enable hibernate
::powercfg -h on


:: Turn on/off Fast Boot
::REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_dWORD /D 0x1 /F
::REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0x0 /F

:: Tweaks
:: http://windows7themes.net/en-us/disable-disk-defragmentation-windows-7-ssd/
