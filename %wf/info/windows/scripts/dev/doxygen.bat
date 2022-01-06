Set P=%~dp0
Set P=%P:~0,-1%
Set CD=%P%
Set PR=d:\WF Erian\Libs\Doxygen\bin\
Set PROJECTNAME=Docs

rem if exist "documentation.chm" del /Q "documentation.chm"
taskkill /IM hh.exe /FI "WINDOWTITLE eq %PROJECTNAME%"
"%PR%doxygen.exe" "%P%\Doxyfile"
if exist "html" rd /S /Q "html"
rem pause