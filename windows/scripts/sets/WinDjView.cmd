assoc .djv=DjVu.Document
assoc .djvu=DjVu.Document
ftype DjVu.Document="%programfiles%\TCWL\Utilites\WinDjView\WinDjView.exe" "%%1"
reg add "HKCR\DjVu.Document" /ve /d "Djv ���㬥��" /f
reg add "HKCR\DjVu.Document\DefaultIcon" /ve /d "%programfiles%\TCWL\Utilites\WinDjView\WinDjView.exe" /f
exit