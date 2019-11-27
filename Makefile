#!/bin/sh -fCeu
# vim:ft=make
#
# SPDX-FileCopyrightText: 2019 Amelyq <amerlyq@gmail.com> and contributors.
#
# SPDX-License-Identifier: MIT
#
:; m=$(readlink -e "$0") && exec "${d:=${m%/*}}"/airy/ctl/makelog -C "$d" -f "$m" MAKEGUARD="$0" "$@" || exit
#
#%SUMMARY: project control center
#%USAGE:
#% * (no-update): $ make flags=
#% * (only mods): $ make -B all/all
#%
.DEFAULT_GOAL = all
# FAIL:( --output-sync=none): keep prompt unaffected -- when scripts inside ask for "sudo" password
MAKEFLAGS += -rR --silent
.NOTPARALLEL:
.SUFFIXES:
this := $(lastword $(MAKEFILE_LIST))
here := $(patsubst %/,%,$(dir $(realpath $(this))))
$(MAKEFILE_LIST): ; @:
.PHONY: .FORCE

# HACK: exec into log wrapper + tty colorizer
ifndef MAKEGUARD
$(subst ,, ) := $(subst ,, )
make := $(here)/airy/ctl/makelog
envp := (let () (unsetenv "MAKE_COMMAND") (setenv "MAKEGUARD" "$(this)") (setenv "MAKEFLAGS" "$(MAKEFLAGS)") (environ))
args := $(subst \|,$( ),$(patsubst %,"%",$(subst \$( ),\|,$(MAKECMDGOALS) $(MAKEOVERRIDES))))
$(guile (execle "$(make)" $(envp) "$(make)" "--file=$(this)" $(args)))
else
unexport MAKEGUARD

### Environment
export TMPDIR      ?= /tmp/$(LOGNAME)
# MAYBE: use $XDG_RUNTIME_DIR
export AIRY_TMPDIR ?= $(TMPDIR)/airy
export AIRY_ROOT   ?= $(HOME)/.local/airy
export AIRY_BIN    ?= $(HOME)/.local/bin
export AIRY_CONFIG ?= $(or $(XDG_CONFIG_HOME),$(HOME)/.config)/airy
export AIRY_CACHE  ?= $(or $(XDG_CACHE_HOME),$(HOME)/.cache)/airy
export AIRY_DATA   ?= $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/airy
export PATH        := $(AIRY_BIN):$(PATH)

# FIXED:(r.airy): on clean install in same login
# BUG: on clean install maps "defaults" to "vi"
EDITOR ?= vi


### Parameters
# BAD: mods may be inside .tar.gz or in subdir -- better to align on Makefile itself "$this"
# repo := $(shell git rev-parse --show-toplevel)

# BUG: some packages (like gcc-multilib) aren't replaced even with -u) due to pacman defaults to [y/N] in --noconfirm
#   => TRY: disable "--noconfirm"
# TODO: remove "-m" => always setup
flags := -mu
skip  :=
tsdir := $(AIRY_CACHE)/ts
&mods = +r.airy-mods-make "tsdir=$(tsdir)" "flags=$(flags)" "skip=$(skip)"

# BET:PERF: use directly $ r.airy-mods-make -- flags=-mu all
# MAYBE:(opt): append -B to force run of chosen target group (e.g. "setup") w/o eliminating all timestamps at once
all: configure upgrade all/all problems
configure: $(tsdir)/--configure-- pacman/setup pacman/install
upgrade: $(tsdir)/--upgrade--
install setup update recache: ; $(&mods) all/$@
reset: ; $(&mods) reset

# [_] FIXME: must "continue" <make all -B> from where it was stopped
#   => currently simple "continue" from same place won't include "-B"
#     BUT:CHECK: if all ts depend on previous already updated ones -- whole chain will be updated
#   ERROR:(r.pacman-loc-package): aur build ${update:+--force}
#      == w/o --force -- will exit successfully even if package itself has errors and can't be built
#     [_] TODO: localize error and create github issue with cmdline snippet to reproduce
continue: install setup update recache

# MAYBE: replace by "cleanup" script in each mod (when you need clean state for accumulating dirs/files)
#  => however, when everything is placed in ~/.cache -- there is no need to clean up ?
#   ALSO: merge "cleanup" with "cfgOpt -r" reset to simulate full reset of some mods
#   OR append actions to "reset" target of "r.airy-mods-make" to be completely user-demanded
# TODO: rename 'recache'/'rR' to smth another to free up '-r' for general reset/remove
# IDEA: create "backup" scripts per each mod to gather all necessary data in one go
#   => so even external locations like ~/work or /data/music can be represented by private user mod ;)
#   => same as "install" -- gather list of paths by env var, but run immediately if launch
## WARN! finally remove symlinks, as all next r.* calls become invalid
# BAD: if symlinks will be always deleted, r.xorg will be never used in core/xorg
# BAD: when deleting all together -- must run whole setup for other cleared areas
#   NEED: clean only systemd ==> link only systemd
# ALSO: ~/.local/share/fonts
clean:
	find -H ~/.config/systemd/user -xdev -depth -mindepth 1 -delete
	find -H '$(AIRY_BIN)' -xdev -depth -mindepth 1 -delete

# NOTE: prepare config system (once)
# BAD: no colorizing here => recursive deps with r.airy-pretty
# WARN: for {pacman, jobs, etc} USE >/dev/tty
# ALSO: use env vars to force $ pacman --color always $ when using TTY w/o redirect
# BAD!RFC: dirty code duplication for init (place wholesome into airy/setup)
#  => BUT: then "airy/setup" must be called even before "all/install" USE? script "init_once" ?
# [_] TODO: consistency
#   OR: make "configure" as separate first step of r.airy-mods-make (inconsistent)
#   OR: call "configure" from --all.pre-- step hook (impossible on clean system)
#   OR: make "airy" mod the very first setup everywhere (hard)
# BUG: clean install -- need install aur before setup
$(tsdir)/--configure--:
	echo '$(@F)'
	mkdir -p '$(@D)' '$(dir $(AIRY_ROOT))' '$(AIRY_BIN)' '$(AIRY_TMPDIR)'
	ln -svfT '$(here)' '$(AIRY_ROOT)'
	ln -svfT '$(realpath $(this))' '$(AIRY_BIN)/airyctl'
	./airy/setup -m
	touch '$@'

# NOTE: connect pacman to tty instead of logs
# BUG:FIXME: only run on "airyctl -B" -- must ignore on simple "airyctl"
$(tsdir)/--upgrade--:
	echo '$(@F)'
	./pacman/update -u > /dev/tty

tags:
	r.airy-cache-tags -L ~/.cache/airy/tags

tags-tree:
	tree --noreport -- ~/.cache/airy/tags | sed 's/\s*->\s*.*//'

problems:
	@echo "Merge/delete all *.pacnew files from pkg updates :: $$ find / -name '*.pacnew'"
	@echo "Then, for each found *.panew, do 'v -d /etc/locale.gen{,.pacnew}'"
	locate .pacnew
	@echo
	@echo "Manually verify necessity of packages outside of airy."
	@echo "INFO:USE:(commands): pacq, pacr, pacR, paclr"
	r.airy-odd-pkgs

help:
	@echo 'Use: $(PHONY)'
	@sed -rn '/^(.*\s)?#%/s///p' '$(this)'
	$(&mods) help

#% NOTE: pass-through unknown targets as mod names
%- :: flags := -muU
%- :: .FORCE $(tsdir)/--configure-- ; $(&mods) $(@:-=)
%  :: .FORCE $(tsdir)/--configure-- ; $(&mods) $@

PHONY := $(shell sed -rn 's/^([A-Za-z0-9-]+):(\s.*|$$)/\1/p' '$(this)'|sort -u)
.PHONY: $(PHONY)
endif
