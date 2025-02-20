#!/usr/bin/env bash

set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

## If the option `use_preview_script` is set to `true`,
## then this script will be called and its output will be displayed in ranger.
## ANSI color codes are supported.
## STDIN is disabled, so interactive scripts won't work properly

## This script is considered a configuration file and must be updated manually.
## It will be left untouched if you upgrade ranger.

## Because of some automated testing we do on the script #'s for comments need
## to be doubled up. Code that is commented out, because it's an alternative for
## example, gets only one #.

## Meanings of exit codes:
## code | meaning    | action of ranger
## -----+------------+-------------------------------------------
## 0    | success    | Display stdout as preview
## 1    | no preview | Display no preview at all
## 2    | plain text | Display the plain content of the file
## 3    | fix width  | Don't reload when width changes
## 4    | fix height | Don't reload when height changes
## 5    | fix both   | Don't ever reload
## 6    | image      | Display the image `$IMAGE_CACHE_PATH` points to as an image preview
## 7    | image      | Display the file directly as an image

## Script arguments
FILE_PATH="${1}"         # Full path of the highlighted file
PV_WIDTH="${2}"          # Width of the preview pane (number of fitting characters)
## shellcheck disable=SC2034 # PV_HEIGHT is provided for convenience and unused
PV_HEIGHT="${3}"         # Height of the preview pane (number of fitting characters)
IMAGE_CACHE_PATH="${4}"  # Full path that should be used to cache image preview
PV_IMAGE_ENABLED="${5}"  # 'True' if image previews are enabled, 'False' otherwise.

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

## Settings
HIGHLIGHT_SIZE_MAX=262143  # 256KiB
HIGHLIGHT_TABWIDTH="${HIGHLIGHT_TABWIDTH:-8}"
HIGHLIGHT_STYLE="${HIGHLIGHT_STYLE:-pablo}"
HIGHLIGHT_OPTIONS="--replace-tabs=${HIGHLIGHT_TABWIDTH} --style=${HIGHLIGHT_STYLE} ${HIGHLIGHT_OPTIONS:-}"
PYGMENTIZE_STYLE="${PYGMENTIZE_STYLE:-autumn}"
OPENSCAD_IMGSIZE="${RNGR_OPENSCAD_IMGSIZE:-1000,1000}"
OPENSCAD_COLORSCHEME="${RNGR_OPENSCAD_COLORSCHEME:-Tomorrow Night}"

## FAIL: git-annex symlinks are resolved and lose extension
# echo "$FILE_PATH" > /t/hi

preview_archive(){ local f=$1 sfx=${2:-#/} avfsdir=$XDG_RUNTIME_DIR/avfs
  # HACK:FIXED:(prevent freeze in recursive archives under fm.avfsdir
  [[ ${f#"$avfsdir"} == "$f" ]] || exit 1

  # MAYBE:BAD:(errpipe=141): | head -n "$PV_HEIGHT"
  local vdir=${avfsdir}${f}$sfx
  # DISABLED:(LC_ALL=C for sorting): cyrillic names are converted to octal escape codes
  # BET: use "broot" for fast-preview of archive contents FAIL: only interactive usage
  # FIXED:REM(tree -x): archives inside annex only show top-level folder
  [[ -d $vdir ]] && tree --noreport -aCL 3 --dirsfirst -- "$vdir" && exit 5
  # TRY: atool --list -- "$f" | tree --noreport -aACL 3 --dirsfirst --fromfile=-
  atool --list -- "$f" && exit 5
  exit 1
}

handle_extension() {
    # shellcheck disable=SC2221,SC2222
    case "${FILE_EXTENSION_LOWER}" in
        ## use AVFS for archive exploration
        # VIZ: $ grep -hroP '\.from = "\.\K[^"]+' /path/to/src/avfs |sort -u| paste -sd'|'
        Z|a|apk|bz|bz2|deb|ear|gz|jar|lz|lzma|rar|sfx|\
        tar|tar.bz2|tar.lz|tar.xz|tar.zst|taz|tbz|tbz2|tgz|tpz|txz|tz|tzst|war|xz|zip|zst)
            preview_archive "$FILE_PATH" ;;
        ## Archive
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            atool --list -- "${FILE_PATH}" && exit 5
            bsdtar --list --file "${FILE_PATH}" && exit 5
            exit 1;;
        rar)
            ## Avoid password prompt by providing empty password
            unrar lt -p- -- "${FILE_PATH}" && exit 5
            exit 1;;
        7z)
            ## Avoid password prompt by providing empty password
            7z l -p -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## PDF
        pdf)
            ## Preview as text conversion
            pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - | \
              fmt -w "${PV_WIDTH}" && exit 5
            mutool draw -F txt -i -- "${FILE_PATH}" 1-10 | \
              fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## BitTorrent
        torrent)
            transmission-show -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## OpenDocument
        # ALSO: Preview odt or similar formats · Issue #2227 · ranger/ranger ⌇⡠⡍⢛⢔
        #   https://github.com/ranger/ranger/issues/2227
        odt|ods|odp|sxw)
            ## Preview as text conversion
            odt2txt "${FILE_PATH}" && exit 5
            ## Preview as markdown conversion
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## OBSOL?
        # doc|xls|ppt) try catdoc "$path" | trim | fmt && exit 3;;

        ## XLSX
        xlsx)
            ## Preview as csv conversion
            ## Uses: https://github.com/dilshod/xlsx2csv
            xlsx2csv -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## HTML
        htm|html|xhtml)
            ## Preview as text conversion
            # w3m -dump "${FILE_PATH}" && exit 5
            # lynx -dump -- "${FILE_PATH}" && exit 5
            elinks -dump "${FILE_PATH}" && exit 5
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            ;;

        ## JSON
        json|ipynb)
            jq --color-output . "${FILE_PATH}" && exit 5
            python -m json.tool -- "${FILE_PATH}" && exit 5
            ;;

        ## Direct Stream Digital/Transfer (DSDIFF) and wavpack aren't detected
        ## by file(1).
        dff|dsf|wv|wvc)
            mediainfo "${FILE_PATH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            ;; # Continue with next handler on failure

        ## @amerlyq
        # BUG: despite this -- !ranger read file as not-UTF8
        # nou) exit 2 ;;

        dlt) r.dlt-convert -cFi "${FILE_PATH}" && exit 3
            ;;

        *,U=[0-9]*:*,*) mshow -nBFN "${FILE_PATH}" && exit 3
            ;;
    esac
}

handle_image() {
    ## Size of the preview if there are multiple options or it has to be
    ## rendered from vector graphics. If the conversion program allows
    ## specifying only one dimension while keeping the aspect ratio, the width
    ## will be used.
    # local DEFAULT_SIZE="1920x1080"
    local DEFAULT_SIZE="1440x1500"  # for 2926x1600 xrandr viewport

    local mimetype="${1}"
    case "${mimetype}" in
        ## SVG
        image/svg+xml|image/svg)
            convert -- "${FILE_PATH}" "${IMAGE_CACHE_PATH}" && exit 6
            exit 1;;

        ## DjVu
        image/vnd.djvu)
            ddjvu -format=tiff -quality=90 -page=1 -size="${DEFAULT_SIZE}" \
                  - "${IMAGE_CACHE_PATH}" < "${FILE_PATH}" \
                  && exit 6 || exit 1;;

        ## Image
        image/*)
            local orientation
            orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${FILE_PATH}" )"
            ## If orientation data is present and the image actually
            ## needs rotating ("1" means no rotation)...
            if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                ## ...auto-rotate the image according to the EXIF data.
                convert -- "${FILE_PATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
            fi

            ## `w3mimgdisplay` will be called for all images (unless overriden
            ## as above), but might fail for unsupported types.
            exit 7;;

        ## Video
        video/*)
            # Thumbnail
            vcsi --grid=3x6 --width="${DEFAULT_SIZE%x*}" --metadata-position=hidden \
              --output="${IMAGE_CACHE_PATH}" -- "${FILE_PATH}" && exit 6
            # Get embedded thumbnail
            ffmpeg -i "${FILE_PATH}" -map 0:v -map -0:V -c copy "${IMAGE_CACHE_PATH}" && exit 6
            # Get frame 10% into video
            ffmpegthumbnailer -i "${FILE_PATH}" -o "${IMAGE_CACHE_PATH}" -s 0 && exit 6
            exit 1;;

        ## PDF
        # application/pdf)
        #     pdftoppm -f 1 -l 1 \
        #              -scale-to-x "${DEFAULT_SIZE%x*}" \
        #              -scale-to-y -1 \
        #              -singlefile \
        #              -jpeg -tiffcompression jpeg \
        #              -- "${FILE_PATH}" "${IMAGE_CACHE_PATH%.*}" \
        #         && exit 6 || exit 1;;


        ## ePub, MOBI, FB2 (using Calibre)
        # application/epub+zip|application/x-mobipocket-ebook|\
        # application/x-fictionbook+xml)
        #     # ePub (using https://github.com/marianosimone/epub-thumbnailer)
        #     epub-thumbnailer "${FILE_PATH}" "${IMAGE_CACHE_PATH}" \
        #         "${DEFAULT_SIZE%x*}" && exit 6
        #     ebook-meta --get-cover="${IMAGE_CACHE_PATH}" -- "${FILE_PATH}" \
        #         >/dev/null && exit 6
        #     exit 1;;

        ## Font
        application/font*|application/*opentype)
            preview_png="/tmp/$(basename "${IMAGE_CACHE_PATH%.*}").png"
            if fontimage -o "${preview_png}" \
                         --pixelsize "120" \
                         --fontname \
                         --pixelsize "80" \
                         --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
                         --text "  abcdefghijklmnopqrstuvwxyz  " \
                         --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
                         --text "  The quick brown fox jumps over the lazy dog.  " \
                         "${FILE_PATH}";
            then
                convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" \
                    && rm "${preview_png}" \
                    && exit 6
            else
                exit 1
            fi
            ;;

        ## Preview archives using the first image inside.
        ## (Very useful for comic book collections for example.)
        # application/zip|application/x-rar|application/x-7z-compressed|\
        #     application/x-xz|application/x-bzip2|application/x-gzip|application/x-tar)
        #     local fn=""; local fe=""
        #     local zip=""; local rar=""; local tar=""; local bsd=""
        #     case "${mimetype}" in
        #         application/zip) zip=1 ;;
        #         application/x-rar) rar=1 ;;
        #         application/x-7z-compressed) ;;
        #         *) tar=1 ;;
        #     esac
        #     { [ "$tar" ] && fn=$(tar --list --file "${FILE_PATH}"); } || \
        #     { fn=$(bsdtar --list --file "${FILE_PATH}") && bsd=1 && tar=""; } || \
        #     { [ "$rar" ] && fn=$(unrar lb -p- -- "${FILE_PATH}"); } || \
        #     { [ "$zip" ] && fn=$(zipinfo -1 -- "${FILE_PATH}"); } || return
        #
        #     fn=$(echo "$fn" | python -c "from __future__ import print_function; \
        #             import sys; import mimetypes as m; \
        #             [ print(l, end='') for l in sys.stdin if \
        #               (m.guess_type(l[:-1])[0] or '').startswith('image/') ]" |\
        #         sort -V | head -n 1)
        #     [ "$fn" = "" ] && return
        #     [ "$bsd" ] && fn=$(printf '%b' "$fn")
        #
        #     [ "$tar" ] && tar --extract --to-stdout \
        #         --file "${FILE_PATH}" -- "$fn" > "${IMAGE_CACHE_PATH}" && exit 6
        #     fe=$(echo -n "$fn" | sed 's/[][*?\]/\\\0/g')
        #     [ "$bsd" ] && bsdtar --extract --to-stdout \
        #         --file "${FILE_PATH}" -- "$fe" > "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$bsd" ] || [ "$tar" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     [ "$rar" ] && unrar p -p- -inul -- "${FILE_PATH}" "$fn" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$zip" ] && unzip -pP "" -- "${FILE_PATH}" "$fe" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$rar" ] || [ "$zip" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     ;;
    esac

    # openscad_image() {
    #     TMPPNG="$(mktemp -t XXXXXX.png)"
    #     openscad --colorscheme="${OPENSCAD_COLORSCHEME}" \
    #         --imgsize="${OPENSCAD_IMGSIZE/x/,}" \
    #         -o "${TMPPNG}" "${1}"
    #     mv "${TMPPNG}" "${IMAGE_CACHE_PATH}"
    # }

    # case "${FILE_EXTENSION_LOWER}" in
    #     ## 3D models
    #     ## OpenSCAD only supports png image output, and ${IMAGE_CACHE_PATH}
    #     ## is hardcoded as jpeg. So we make a tempfile.png and just
    #     ## move/rename it to jpg. This works because image libraries are
    #     ## smart enough to handle it.
    #     csg|scad)
    #         openscad_image "${FILE_PATH}" && exit 6
    #         ;;
    #     3mf|amf|dxf|off|stl)
    #         openscad_image <(echo "import(\"${FILE_PATH}\");") && exit 6
    #         ;;
    # esac
}

handle_mime() {
    local mimetype="${1}"
    case "${mimetype}" in
        ## RTF and DOC
        text/rtf|*msword)
            ## Preview as text conversion
            ## note: catdoc does not always work for .doc files
            ## catdoc: http://www.wagner.pp.ru/~vitus/software/catdoc/
            catdoc -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## DOCX, ePub, FB2 (using markdown)
        ## You might want to remove "|epub" and/or "|fb2" below if you have
        ## uncommented other methods to preview those formats
        *wordprocessingml.document|*/epub+zip|*/x-fictionbook+xml)
            ## Preview as markdown conversion
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## E-mails
        message/rfc822)
            # ALT: https://github.com/djcb/mu
            # mu view -- "${FILE_PATH}" && exit 5
            mshow -nBFN "${FILE_PATH}" && exit 5
            exit 2;;

        ## XLS
        *ms-excel)
            ## Preview as csv conversion
            ## xls2csv comes with catdoc:
            ##   http://www.wagner.pp.ru/~vitus/software/catdoc/
            xls2csv -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## Text
        text/* | */xml)
            ## Syntax highlight
            if [[ "$( stat --printf='%s' -- "${FILE_PATH}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
                exit 2
            fi
            if [[ "$( tput colors )" -ge 256 ]]; then
                local pygmentize_format='terminal256'
                local highlight_format='xterm256'
            else
                local pygmentize_format='terminal'
                local highlight_format='ansi'
            fi
            # env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight \
            #     --out-format="${highlight_format}" \
            #     --force -- "${FILE_PATH}" && exit 5
            env COLORTERM=8bit bat --theme='TwoDark' --paging=never --color=always --style="plain" \
                -- "${FILE_PATH}" && exit 5
            pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}"\
                -- "${FILE_PATH}" && exit 5
            exit 2;;

        ## DjVu
        image/vnd.djvu)
            ## Preview as text conversion (requires djvulibre)
            djvutxt "${FILE_PATH}" | fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## Image
        image/*)
            ## Preview as text conversion
            # img2txt --gamma=0.6 --width="${PV_WIDTH}" -- "${FILE_PATH}" && exit 4
            # timg -g${PV_WIDTH}x${PV_HEIGHT} "${FILE_PATH}"
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## Video and audio
        video/* | audio/*)
            mediainfo "${FILE_PATH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## ELF files (executables and shared objects)
        application/x-executable | application/x-pie-executable | application/x-sharedlib)
            file --dereference --brief -- "${FILE_PATH}"
            echo
            readelf -WCa "${FILE_PATH}" && exit 5
            # DEV: sort symbols in columns: imported (U), exported (T), data (D)
            nm -n -- "${FILE_PATH}" && exit 4
            # ALT: ldd
            # ALT: readelf -dW
            exit 1;;

        ## @amerlyq
        # application/x-sqlite3)
        #   # BUG: even in readonly mode it creates -wal files
        #   sqlite3 "$path" .fullschema .dbinfo .quit && exit 5
        #   ;;

        application/zip)    preview_archive "$FILE_PATH" "#uzip/"       ;;
        application/gzip)   preview_archive "$FILE_PATH" "#ugz#utar/"   ;;
        application/zstd)   preview_archive "$FILE_PATH" "#uzstd#utar/" ;;
        application/x-lzip) preview_archive "$FILE_PATH" "#ulzip#utar/" ;;
    esac
}

handle_fallback() {
    # echo '----- File Type Classification -----' && file --dereference --brief -- "${FILE_PATH}" && exit 5
    # exit 1
    file --dereference --brief -- "${FILE_PATH}"  # | sed 's/,\s*/\n/g'
    [[ -s ${FILE_PATH} ]] || exit 1
    echo  # printf "<$(printf "=%.0s" {1..62})>\n"
    # shellcheck disable=SC2017
    local maxcol=$(( (PV_WIDTH-6) / 7 * 2 ))  # actualwidth=$((height/2*7+6))
    local maxln=$(( PV_HEIGHT - 2 ))
    # BAD: "-T" is not supported anymore
    r2 -qnSNN -c'eco solarized' -c'e scr.color=2' -c"pxl $maxln" "${FILE_PATH}" && exit 4
    # TRY:FIND:(number of pairs/width): https://github.com/radareorg/radare2/blob/master/libr/core/cmd_print.c
    # r2 -qnSTNN -c'eco solarized' -c'e scr.color=2' -c"pxx $((maxcol*maxln))" "${FILE_PATH}" && exit 4
    xxd -c "$maxcol" -l $((maxcol*maxln)) "${FILE_PATH}" | sed 's/^0\{4\}//' && exit 4
}


MIMETYPE="$( file --dereference --brief --mime-type -- "${FILE_PATH}" )"
if [[ "${PV_IMAGE_ENABLED}" == 'True' ]]; then
    handle_image "${MIMETYPE}"
fi
handle_extension
handle_mime "${MIMETYPE}"
handle_fallback

exit 1
