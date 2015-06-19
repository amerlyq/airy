#!/bin/bash

VIMC="$HOME/.cache/vim"  # Dir for .swp, backup, ... files
FONT="$VIMC/powerline-fonts/DejaVuSansMono"

PATH="/c/Program Files (x86)/GnuWin32/bin:$PATH"
if ! wget --version &> /dev/null; then
    echo "You must install 'wget for windows',
    so spell checking and neocomplete could work in vim on windows"
fi


### THEMES ###
case "$1" in
dark|light) printf "\
set background=$1
colorscheme solarized
" > "$VIMC/vim_theme"
;; esac


### SPELL ###
if [ ! -d "$VIMC/spell" ] && wget --version &> /dev/null; then
    mkdir -p "$VIMC/spell"
    src='http://ftp.vim.org/pub/vim/runtime/spell'
    for nm in ru en uk; do ( cd "$VIMC/spell"
        wget "$src/${nm}.utf-8.spl" && wget "$src/${nm}.utf-8.sug"
    ) done
fi
# For vim-easytags
#touch ~/.vimtags


# If neobundle don't run on Win
# %HOME% = %USERPROFILE%
# %TEMP% = %USERPROFILE%\AppData\Local\Temp
# %TMP% = %USERPROFILE%\AppData\Local\Temp


### FONTS ###
# http://www.msfn.org/board/topic/119612-how-to-install-a-font-via-the-command-line/
winFontInstall() {
    local nm ftp
    ROOT_FONTS="/c/Windows/Fonts/"
    REG_FONTS="HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"
    # shutdown -r -f -t 10 -c "Reboot may be required for Fonts installation"
    for file in $1/*.*tf; do
        nm="${file##*/}"
        [ "${nm##*.}" == "otf" ] && ftp="(OpenType)"
        [ "${nm##*.}" == "ttf" ] && ftp="(TrueType)"
        cp -u "$file" "$ROOT_FONTS"
        echo "$nm"
        #reg add "\"$REG_FONTS\" /f /v \"${nm%.*} $ftp\" /t REG_SZ /d \"$nm\""
        reg add "$REG_FONTS" //v "${nm%.*} $ftp" //t REG_SZ //d "$nm" //f
    done
    echo "Warning! Need reboot now!"
    ## Manually:
    # REG ADD "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts /f /v DejaVu Sans Mono Bold Oblique for Powerline (TrueType) /t REG_SZ /d DejaVu Sans Mono Bold Oblique for Powerline.ttf"
}

## Powerline resources
# Plugin (the best): https://github.com/bling/vim-airline
# https://powerline.readthedocs.org/en/latest/installation/linux.html#font-installation
# https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf
# https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf

# http://www.marksimonson.com/fonts/view/anonymous-pro
winFontInstall "$FONT"

## LUA
if wget --version &> /dev/null; then
    # http://lua-users.org/wiki/LuaBinaries
    LUA_DLL="$HOME/.vim/lua52.dll"
    rm -f "$LUA_DLL"
    src='http://sourceforge.net/projects/luabinaries/files/latest/download'
    wget -c "$src" -O "$LUA_DLL"
    echo "Lua dll installed"
fi

### PLUGINS ###
vim +NeoBundleClearCache +NeoBundleCheckUpdate +qall
