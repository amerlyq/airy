#!/bin/bash

# http://commons.wikimedia.org/wiki/Help:Creating_a_DjVu_file
# http://debiania.blogspot.com/2010/06/djvu-linux.html

source ~/.shenv
[ $? -ne 0 ] && exit
source ~/.shell/funcs
[ $? -ne 0 ] && exit

if [ "$CURR_PLTF" == "MINGW" ]; then
    pr7zip="/c/Program Files/7-Zip"
    prImMagick="/d/PR Portable/Aims/DjVu/ImageMagick-6.8.9-0"
    prDjvuEnc="/d/PR Portable/Aims/DjVu/DjVu Small v0.4.4/bin"
    PATH="$pr7zip:$prImMagick:$prDjvuEnc:$PATH"
    #echo $PATH
    WORK_DIR="/g/Manga"
    prDjvu=documenttodjvum
else
    WORK_DIR="$PWD"
    prDjvu="$HOME/.wine/drive_c/Program Files (x86)/DjVu Small v0.4.4/bin/documenttodjvum.exe"
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"


SRC=$WORK_DIR/src
DST=$WORK_DIR/tmp
LOG=$DST/log
DJVU=$WORK_DIR/djvu
READY=$WORK_DIR/ready
DST_ORG=$DST/origin
DST_PRC=$DST/processed

mkdir -p "$SRC"
mkdir -p "$DST"
mkdir -p "$DST_ORG"
mkdir -p "$DST_PRC"



# сделать проверку по типам: если в сорцах обнаружен пдф или джвю -- то извлечь из него картинки,
# архивы -- извлечь, если сразу найдены картинки -- то просто скопировать их.



getFileList() { #$1 - fulldirpath, $2 - fulllistname, $3 - brackets
    local f s
    s="$3"
    rm -f "$2" # reset content of file
    # ls *.[jJ][pP][gG] | sort -r > filelist
    # ls $SRC | xargs -n 1 -i echo "$SRC/{}"
    for f in "$1"/*; do
        if [ "$CURR_PLTF" == "MINGW" ]; then
            lst="${f:1:1}:${f:2}"
            lst=$s"${lst//\//\\}"$s
        else lst=$s"$f"$s; fi
        echo "$lst" >> "$2"
    done
    if [ "$CURR_PLTF" != "MINGW" ] && [ -z "$3" ]; then
        iconv -f UTF-8 -t CP1251 "$2" -o "$2"
    fi
    echo "Done: $1 -> ${2##*/}"
}

renameConsequential() { #$1 - dirpath (recursive),  # build mv command
    local ext="tif"
    cd "$1"
    find . -name "*.$ext" | sort \
    | awk '{ printf "mv \"%s\" \"%04d.tif\"\n", $0, NR }' | bash
}

#makeDstBackup safeLinkRemove "$dst"
bakDir() {
    if [ -e "$1/$2" ]; then
        [ -e "$1/#" ] && rm -rf "$1/#"
        mkdir -p "$1/#"
        mv "$1/$2" "$1/#/$2"
    fi
}

bakFile() {
    if [ -f "$1" ]; then
        mkdir -p "${2%/*}"
        [ -f "$2" ] && mv "$2"{,.bak}
        mv "$1" "$2"
    fi
}

extractPics() {
    # x -y   # Extract, yes to all
    # -ai@flist.txt or -ai!*.rar -a!*.zip -ai!*.7z    # include archs from srcs
    if [ "$CURR_PLTF" == "MINGW" ]; then
        7z x -y "$1" -o "$2"
    else
        atool "$1" --force --extract-to="$2"
    fi
}

convertPics() {
    local to lst
    if [ "$CURR_PLTF" == "MINGW" ]; then
        to=$(unix2win "$2")
        lst=$(unix2win "$1")
    else
        to="$2"
        lst="$1"
    fi
    # 150x150 - чтобы при upsample=2 внутренний dpi\[Rule]300, а не 600,
    # before posterize: -colorspace Gray
    # ALT: vips | http://www.vips.ecs.soton.ac.uk/index.php?title=Stable
    mogrify -verbose -colorspace sRGB -despeckle -filter Lanczos -interpolate filter -resize 2400x1600 -level 5%,95% -auto-gamma -posterize 32 -format tif -compress lzw -density 150x150 -type Palette -path "$to" @"$lst"
    # nconvert -npcd 2 -size 256x256+0 -ctype grey -corder inter -out tiff -dpi 300 -ratio -rtype lanczos -rflag decr -resize 1600 1376 -dither -grey 256 -gamma 0.90 -autocontrast -soften 75 -noise reduce -eedge 2 -edetail -posterize 32 "D:\&Documents\+Working\Images\PsInput\Gantz_v04_c035-046_rus\GANTZ_v04c35p015.jpg"
}

convertDjvu() {
    # Under WINE
        # --togray
    local lst="$1" #"$(unix2win "$1")"
    ARGS="--dpi=300 --upsample=2 --pix-filter-level=12 --shape-filter-level=30 --threshold-level=56 --inversion-level=4 --bg-subsample=2 --quality=24 --lossless --fg-quality=1 --pages-per-dict=10 --jb2-format=color --verbose"
    if [ "$CURR_PLTF" == "MINGW" ]
    then "$prDjvu" $ARGS --filelist="$lst" "$2"
    else wine "$prDjvu" $ARGS --filelist="$lst" "$2" ; fi
}

oneTask() {
    fnm="$1"
    bnm="${fnm##*/}"
    bnm="${bnm%.*}"
    mkdir -p "$DST_PRC/$bnm"

    extractPics "$fnm" "$DST_ORG/$bnm"
    #there you need test pictures if there are <16kB then output list and stop
    # or another variant -- ignore all of them but log errors for my knowing.
    getFileList "$DST_ORG/$bnm" "$DST/origin.lst" \"
    convertPics "$DST/origin.lst" "$DST_PRC/$bnm"
    renameConsequential "$DST_PRC/$bnm"
    getFileList "$DST_PRC/$bnm" "$DST/processed.lst"
    convertDjvu "$DST/processed.lst" "$DST/$bnm.djvu"

    ## Clear temp pictures and move files
    #TODO: add conditions to _not_ move or delete if error!
    bakDir "$DST_ORG" "$bnm"
    bakDir "$DST_PRC" "$bnm"
    bakFile "$DST/$bnm.djvu" "$DJVU/$bnm.djvu"
    bakFile "$fnm" "$READY/${fnm##*/}"
}

mkdir -p "$LOG"
for fnm in "$SRC"/*; do
    if [ -e "$fnm" ]; then
        oneTask "$fnm" | tee "$LOG/${fnm##*/}.log"
    fi
done

amPause
