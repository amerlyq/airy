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
cd airy
make           # install basic 'airy' symlinks
make all       # clean all and then install pkgs
make continue  # to continue installation after error was fixed
```
Go make some tea, in one minute basic shell tools will be installed.


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
#!/bin/bash -eu
cd "$(dirname "$(readlink -e "$0")")"

airy=~/aura/airy
[[ -d $airy ]] || (mkdir -p "${airy%/*}" &&
  git clone 'https://github.com/amerlyq/airy' "$airy")

config=${XDG_CONFIG_HOME:-~/.config}/airy
[[ -d ~/.bin && -L $config ]] || (cd "$airy" && make install)
[[ -L $config ]] || (echo 'Err: $config must be symlink'; exit)

[[ :$PATH: == *:$HOME/.bin:* ]] || export PATH=~/.bin:$PATH

repo=$(git rev-parse --show-toplevel)
linkcp "$repo/prf" "$config/prf"
linkcp "$repo/prf/$(hostname)" "$config/profile"
linkcp "$repo/mods" "$config/mod/${repo##*/}"
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
AIRY_MODS=( airy pacman git zsh vim ranger tmux xorg )

### Git ###
MAIN_NAME="<Full Name>"
MAIN_MAIL="username@gmail.com"
MAIN_SKYPE="<username>"
```

Profiles can be nested/inherited.
This allows to distribute settings and nicely reuse parts of configs for similar hosts.
```bash
source "${CURR_DIR_PRF:?}/home" || return
CURR_PROF=home_vbox
AIRY_SKIP+=( browser )
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
