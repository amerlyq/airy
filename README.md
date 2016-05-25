airy
=====

Modular system configuration and package installation.
  * Encapsulates user settings to manage by version control systems.
  * Aimed for development purposes with bias to vim, tiling WM and terminals.
  * Automatic setup on clean system, with following update/maintenance.


## Install ##

Currently supported host systems:
  * Arch Linux (preferable)
  * Ubuntu-based distro (clean if possible)

If you wish to feel what it's like, default setup contains only necessary
symlinks and terminal tools, preserving your system as much as possible.
```bash
mkdir -p ~/aura && cd ~/aura
git clone https://github.com/amerlyq/airy
cd airy && ./setup -iu
```
Go make some tea, in one minute basic shell tools will be installed.

Need more modules from some subdirectory?
```bash
./setup       # after changing setup scripts -- refreshes system configuration
./setup -u    # additionally executes -u script sections (sudo/update/etc)
./setup -u /  # choose currently preferred applications
./setup -iu   # once a week -- installs packages and update their configs
./setup -riu  # after adding new module or changing mods list in profile
./setup -fri  # re-install pkgs one-by-one (when replacing by alternatives)
# Install all modules:
./setup -iu  dev         # with exact name '*/dev'
./setup -iu  dev/        # all inside '*/dev/*' w/o 'dev' itself
./setup -iu /dev/        # only 'cfg/dev' in root dir
./setup -iu hex firefox  # multiple from any subdir
```
> Better idea would be to create your own mods profile and keep it safe.


## Private parts ##

You can keep your system profiles and private modules/resources in your own
private repository (gitlab.com, bitbucket.com, dropbox, etc).

Overall directories structure (in repo's root or some subdirectory) is next:
```
repo
├── mods
│   ├── fonts
│   │   └── setup
│   └── mutt_gmail
│       ├── install
│       └── setup
├── prf
│   ├── hostname1  # home
│   ├── hostname2  # work
│   └── hostname3  # server (headless)
└── setup
```

Main `repo/setup` must be launched on clean system before everything else.
It will symlink your choosen profile/modules and launches system setup.
```bash
#!/bin/bash -e
cd $(dirname $(readlink -m ${0}))
main=~/aura/airy
cache=${CURR_DIR_CACHE:-~/.cache/airy}
repo=$(git rev-parse --show-toplevel)
mkdir -p "$cache/mods"

ln -svfT "$PWD/prf" "$cache/prf"
ln -svfT "$PWD/prf/$(hostname)" "$cache/profile"
ln -svfT "$PWD/mods" "$cache/mods/${repo##*/}"
## OR: link only choosen modules
# ln -svfT "$PWD/mods/fonts" "$cache/mods/fonts"

[[ -d $main ]] || (mkdir -p "${main%/*}" &&
    git clone 'https://github.com/amerlyq/airy' "$main")
"$main/setup" -riu
```

In such way your own clean system setup will be as simple as:
```bash
mkdir -p ~/aura && cd ~/aura
git clone https://github.com/$yourname/$reponame
cd $reponame && ./setup
```
Note, that in case of using Xorg mods, to fully setup system you must run
setup command inside Xorg session -- because some vars (like dpi)
impossible to extract from plain console. Therefore on clean system install
the setup script must be run twice -- in console and then in Xorg.


## Profile ##

Each profile `prf/hostname` is written in plain bash.
These text files usually non-executable and sourced by scripts explicitly.
```bash
# vim: ft=sh
CURR_PROF=home
PKG_LIST=(shell shell/ dev dev/ term/ xorg xorg/ net/ /)
PKG_SKIP=(sql latex nfs tftp skype serial xmind urxvt i3)

### Git ###
MAIN_NAME="<Full Name>"
MAIN_MAIL="username@gmail.com"
MAIN_SKYPE="<username>"
```

You can take advantage of bash expansion and compose more complex package set:
```bash
PKG_LIST=( /shell{,/} /core{,/init} /io/{audio,touchpad,logitech} /dev{,/{python,ruby,etc,git,hg}} /{term,re,xorg,net,media,browsers}{,/} /game / )

PKG_SKIP=(/browser/{surf,uzbl,vimb} /dev/{eclipse,java,latex,sql,tizen} /io/{jtag,serial} /media/{skype,xmind} /net/{nfs,synergy,tftp} /term/urxvt /xorg/i3)
```

Profiles can be nested/inherited.
This allows to distribute settings and nicely reuse parts of configs for similar hosts.
```bash
source "${CURR_DIR_PRF:?}/home" || return
CURR_PROF=home_vbox
PKG_SKIP+=( /browser/ )
MAIN_MAIL="vboxuser@email.com"
```

Example how to use profile vars in your own modules/scripts:
```bash
#!/bin/bash -e
source ~/.shell/profile
...
./muttprf.gen ${MAIN_MAIL:?}
./gtk-theme.gen "${CURR_DIR_CACHE:?}/theme"
```
