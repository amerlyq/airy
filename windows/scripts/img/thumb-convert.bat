rem convert 2.pdf -resize 3200x2800  002.tif
rem convert -density 300 -compress lzw 2.pdf 2ABC-%d.tiff
if exist "thumbs" del /q "thumbs"
if not exist "thumbs" mkdir thumbs

mogrify  -format jpg -path thumbs -thumbnail 150x150 *.pdf
rem mogrify  -format jpg -path thumbs -thumbnail 150x150 *.tif
pause

gswin64c -dNOPAUSE -q -r600 -sDEVICE=tiffg4 -dBATCH -dFirstPage=1 -dLastPage=2 -sOutputFile=2_%%04d.tif 2.pdf
rem gswin64c -h
pause

rem SEE E:\&Dld\PR\ImageMagick\Techniques\17. Fourier Transforms -- IM v6 Examples.mht, High Pass

nconvert -npcd 2 -size 256x256+0 -ctype grey -corder inter -out tiff -ratio -rtype hermite -resize 3200 2800 "E:\+Manga\#\007.tif" "E:\+Manga\#\040.tif"
