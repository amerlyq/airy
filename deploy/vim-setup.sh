#!/bin/bash
# See: vimregex.com

source "$HOME/.bash/functions"
FONT_DIR="$HOME/.vim/res/powerline-fonts"
FONT_USE="DejaVuSansMono"

CVIM="$HOME/.cache/vim"
mkdir -p "$CVIM" # Dir for .swp and backup edited files

case $1 in
    dark)   printf "set background=dark\ncolorscheme solarized\n"  > "$CVIM/vim_theme" ;;
    light)  printf "set background=light\ncolorscheme solarized\n" > "$CVIM/vim_theme" ;;
esac

# If neobundle don't run on Win
# %HOME% = %USERPROFILE%
# %TEMP% = %USERPROFILE%\AppData\Local\Temp
# %TMP% = %USERPROFILE%\AppData\Local\Temp

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
        #REG ADD "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts /f /v DejaVu Sans Mono Bold Oblique for Powerline (TrueType) /t REG_SZ /d DejaVu Sans Mono Bold Oblique for Powerline.ttf"
}


# Powerline resources
# Plugin (the best): https://github.com/bling/vim-airline
# https://powerline.readthedocs.org/en/latest/installation/linux.html#font-installation
# https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf
# https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
# TODO: symlinks instead of straight copy???



if [ "$1" == "fonts" ] || [ ! -d "$FONT_DIR" ]; then
    # Patched fonts for windows usage:
    git clone --depth=1 https://github.com/Lokaltog/powerline-fonts "$FONT_DIR"
fi


if [ "$CURR_PLTF" == "Linux" ]; then
    # For vim-easytags
    #touch ~/.vimtags

    if [ ! -e "$HOME/.fonts/PowerlineSymbols.otf" ]; then
        mkdir -p ~/.fonts/
        # See: https://wiki.archlinux.org/index.php/Font_Configuration#Fontconfig_configuration
        cp ~/.vim/res/PowerlineSymbols.otf ~/.fonts/   # ~/.fonts.conf.d/ is deprecated
        mkdir -p ~/.config/fontconfig/conf.d/
        cp ~/.vim/res/10-powerline-symbols.conf ~/.config/fontconfig/conf.d/
        fc-cache -vf ~/.fonts
    fi

    FONT_DST="$HOME/.fonts/$FONT_USE"
    if [ ! -d "$FONT_DST" ]; then
        cp -urf "$FONT_DIR/$FONT_USE" "$FONT_DST"
        fc-cache -vf ~/.fonts  # check active name with fc-list
    fi
fi

if [ "$CURR_PLTF" == "MINGW" ]; then
    # http://www.marksimonson.com/fonts/view/anonymous-pro
    winFontInstall "$FONT_DIR/$FONT_USE"

    PATH="/c/Program Files (x86)/GnuWin32/bin:$PATH"
    if wget --version &> /dev/null; then
        # http://lua-users.org/wiki/LuaBinaries
        LUA_DLL="$HOME/.vim/lua52.dll"
        rm -f "$LUA_DLL"
        wget -c "http://sourceforge.net/projects/luabinaries/files/latest/download" -O "$LUA_DLL"
        echo "Lua dll installed"
    else
        echo "You must install 'wget for windows' so neocomplete can work in vim"
    fi

fi
echo "Vim font '$FONT_USE' installed"

if [ "$1" == "-u" ]; then
    vim +NeoBundleClearCache +NeoBundleCheckUpdate #+qall
    # vim +NeoBundleInstall +qall
fi

