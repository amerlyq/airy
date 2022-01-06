Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

@rem Set from="c:/tmp/318_0032_01.MP4"
@rem Set to="c:/tmp/318_0032_01.avi"

@rem Set pr=D:\PR Portable\Convert\ffmpeg\bin\
@rem D:
@rem cd "%pr%"

Set args= -r 30 -s 1280x720 -q:v 3 -b:v 3500k -vcodec h264 -an -aspect 16:9 -f avi
Set suf=_vdb.avi

ffmpeg -i epub_d1.mp4 %args% epub_d1%suf%
ffmpeg -i epub_d2.mp4 %args% epub_d2%suf%

ffmpeg -i mpeg_d1.mp4 %args% mpeg_d1%suf%
ffmpeg -i mpeg_d2.mp4 %args% mpeg_d2%suf%
ffmpeg -i mpeg_d3.mp4 %args% mpeg_d3%suf%

pause