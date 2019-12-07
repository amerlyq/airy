airy
=====

Modular system configuration and package installation.
  * Encapsulates user settings to manage by version control systems.
  * Aimed for development purposes with bias to vim, tiling WM and terminals.
  * Automatic setup on clean system, with following update/maintenance.


Currently supported host systems:
  * Arch Linux (preferable)
  * Ubuntu-based distro (clean if possible)


## Initial ##

TEMP: Manually symlink or mount --bind

```bash
ln -s  /data/chroots /chroot
ln -s  /home/work    /work
ln -s  ~/Downloads   /_dld
ln -s  /data/music   ~/.config/mpd/music
```
ALSO
 * encrypt your SSH keys
 * add SSH keys to github/gitlab


## Install ##

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
├── airy
│   ├── hostname1  # home
│   ├── hostname2  # work
│   └── hostname3  # server (headless)
├── fonts
│   └── setup
├── mutt
│   └── acc
│       ├── home
│       └── work
└── Makefile
```

Main `repo/Makefile` must be launched on clean system before everything else.
It will symlink your chosen profile/modules and launches system setup.
```make
#!/usr/bin/make -f
.DEFAULT_GOAL = install
MAKEFLAGS += -rR --silent
d_airy := $(HOME)/aura/airy
d_cfg := $(or $(AIRY_CONFIG),$(or $(XDG_CONFIG_HOME),$(HOME)/.config)/airy)
prf := $(shell pwd)/airy/$(shell hostname)
install:
	$(MAKE) -C '$(d_airy)' -- configure
	ln -svfT '$(prf)' '$(d_cfg)/profile'
```

In such way your own clean system setup will be as simple as:
```bash
mkdir -p ~/aura && cd ~/aura
git clone https://github.com/amerlyq/airy
git clone https://gitlab.com/$yourname/$airyprivate
cd $airyprivate
make
cd ../airy
make -B
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
dprf=$(dirname "$(readlink -e "$BASH_SOURCE")")
AIRY_OVERLAY_PATH=${dprf%/*}
source "$dprf/home" || return
CURR_PROF=home_vbox
AIRY_SKIP+=( browser )
MAIN_MAIL="vboxuser@email.com"
```

Example how to use profile vars in your own modules/scripts:
```bash
#!/bin/bash -e
source ~/.shell/profile
...
r.mutt-acc ${MAIN_MAIL:?}
```
