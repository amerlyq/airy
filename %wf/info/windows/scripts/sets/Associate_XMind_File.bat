SET XMIND=%CD%\xmind.exe

ASSOC .xmind=
FTYPE XMind.Workbook.3=
FTYPE XMind.Workbook.2=

FTYPE XMind.Workbook.3=%XMIND% "%%1"
FTYPE XMind.Workbook.2=%XMIND% "%%1"
ASSOC .xmind=XMind.Workbook.3