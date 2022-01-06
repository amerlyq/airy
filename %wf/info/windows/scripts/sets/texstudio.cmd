Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

assoc .tex=Tex.Document
assoc .bib=Tex.Document
ftype Tex.Document="%CD%\texstudio.exe" "%%1"
reg add "HKCR\Tex.Document" /ve /d "TeX and LaTeX files" /f
reg add "HKCR\Tex.Document\DefaultIcon" /ve /d "%CD%\texstudio.exe" /f
pause
exit