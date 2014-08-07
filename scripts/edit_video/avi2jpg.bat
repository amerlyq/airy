Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

for %%A in (*.avi) do (if exist %%~nA (del /Q %%~nA) else (mkdir %%~nA)) & ffmpeg -i %cd%\%%A -r 30 -f image2 -s 1280x720 -qscale 3 -aspect 16:9 %cd%\%%~nA\%%06d.jpg"

pause