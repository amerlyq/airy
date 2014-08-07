title FR-auto %~1

del /q "c:\Program Files\LizardTech\FR\aga\*.*"
xcopy /i /h /y "c:\Program Files\LizardTech\FR\BP" "c:\Program Files\LizardTech\FR\aga\"

setlocal
set pagenumber=1
:loop1
call "c:\Program Files\LizardTech\BPholding\save-page.bat" %1 "c:\Program Files\LizardTech\FR\aga\" 2>>nul
if errorlevel 1 goto aga
set /a pagenumber=%pagenumber%+1
goto loop1
:aga
endlocal

for %%i in ("c:\Program Files\LizardTech\FR\aga\????.djvu") do (echo Page %%~ni&"c:\Program Files\LizardTech\Lizardtech Document Express Enterprise\bin\djvudecode.exe" --verbose --layer=foreground "%%~i" "%%~dpni.tif" | find "dpi")
for %%i in ("c:\Program Files\LizardTech\FR\aga\????.djvu") do if not exist "c:\Program Files\LizardTech\FR\aga\%%~ni.tif" ("c:\Program Files\LizardTech\BPholding\djvudump.exe" "%%~i" | find "INFO" > 1.txt & for /F "usebackq tokens=4,5,7 delims=x " %%I in (1.txt) do c:\totalcmd\XnView\nconvert.exe -o "%%~dpni.tif" -binary halft90 -c 7 -canvas %%I %%J center -bgcolor 255 255 255 -dpi %%K -quiet "c:\totalcmd\XnView\blank_pages\blank.tif"& echo Blanc page %%~ni restored)

del /q "c:\Program Files\LizardTech\FR\aga\????.djvu"

for /L %%z in (1,1,%NUMBER_OF_PROCESSORS%) do (echo Starting FineBR.exe instance %%z&start /b /d"c:\Program Files\LizardTech\FR" FineBR.exe FarbfehnGestunGehrat "c:\Program Files\LizardTech\FR\aga" 0 "Software\ABBYY\FineReader\8.00" "Software\ABBYY\FineReader\8.00" 1)

@echo.
@echo.
@echo Please wait...
@echo.
@echo off
@:loop
@ping localhost -n 30 > nul
@for %%i in ("c:\Program Files\LizardTech\FR\aga\????.tif") do if not exist "c:\Program Files\LizardTech\FR\aga\%%~ni.frf" (echo %%~ni.frf doesn't exist - continue for another 30 seconds & goto loop)

taskkill /f /im FineBR.exe
rem For auto-str keys: -r -i -p 1
"c:\Program Files\LizardTech\OCR-new\FRFgrab.exe" -i -p 1 "c:\Program Files\LizardTech\FR\aga\*.frf" > "c:\Program Files\LizardTech\OCR-new\book.txt"
rem "c:\Program Files\LizardTech\OCR-new\sed-3.59.exe" "s/\\050/(/g" "c:\Program Files\LizardTech\OCR-new\book1.txt" > "c:\Program Files\LizardTech\OCR-new\book.txt"
copy %2 "%~dpn2.OCR.djvu"
"c:\Program Files\LizardTech\OCR-new\djvused.exe" -f "c:\Program Files\LizardTech\OCR-new\book.txt" "%~dpn2.OCR.djvu"
