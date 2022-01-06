Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

set now=%DATE: =0% %TIME: =0%
for /f "tokens=1-7 delims=/-:., " %%a in ( "%now%" ) do (
    set now=%%c%%b%%a_%%d%%e%%f
)

Set pr=D:\PR Portable\Convert\ffmpeg\bin\
D:
cd "%pr%"

@rem ffmpeg -r 30 -y -i "%cd%\render\%%04d.jpg" -qscale 2 -b 3500k -vcodec wmv2 -an "%cd%\SDRM_demo_30s_%now%.wmv"

ffmpeg -r 30 -y -i "%cd%\render\%%04d.jpg" -b 4000k -vcodec wmv2 -an "%cd%\SDRM_demo_50s_%now%.wmv"
pause