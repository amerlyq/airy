#!/usr/bin/env -S r.airy-makelog -f
#%USAGE:
#% * (no-update): $ ./$0 flags=
#%
.DEFAULT_GOAL = all
# HACK:( --output-sync=none): keep prompt unaffected -- when scripts inside ask for "sudo" password
# CHECK: seems like pacman isn't connected to tty despite :: exec > /dev/tty && exec < /dev/tty
MAKEFLAGS += -rR --silent
.NOTPARALLEL:
.SUFFIXES:
this := $(realpath $(lastword $(MAKEFILE_LIST)))
here := $(patsubst %/,%,$(dir $(this)))
$(notdir $(this)): ;
PHONY := $(shell sed -rn 's/^([A-Za-z0-9-]+):(\s.*|$$)/\1/p' '$(this)'|sort -u|xargs)
.PHONY: $(PHONY)

# [_] BET:FIXME: instead of shebang to r.airy-makelog -- use pass-through recipe into it

# BAD: mods may be inside .tar.gz or in subdir -- better to align on Makefile itself "$this"
# repo := $(shell git rev-parse --show-toplevel)

### Parameters
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

# BUG: some packages (like gcc-multilib) aren't replaced even with -u) due to pacman defaults to [y/N] in --noconfirm
#   => TRY: disable "--noconfirm"
# TODO: remove "-m" => always setup
flags := -mu
skip  :=
tsdir := $(AIRY_CACHE)/ts
&mods = +r.airy-mods-make "tsdir=$(tsdir)" "flags=$(flags)" "skip=$(skip)"

# BET:PERF: use directly $ r.airy-mods-make -- flags=-mu all
# MAYBE:(opt): append -B to force run of chosen target group (e.g. "setup") w/o eliminating all timestamps at once
all: configure upgrade all/all
configure: $(tsdir)/--configure--
upgrade: $(tsdir)/--upgrade--
install setup update recache: ; $(&mods) all/$@
reset: ; $(&mods) reset

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
$(tsdir)/--configure--:
	echo '$(@F)'
	mkdir -p '$(dir $(AIRY_ROOT))' '$(AIRY_BIN)' '$(AIRY_TMPDIR)'
	ln -svfT '$(here)' '$(AIRY_ROOT)'
	ln -svfT '$(realpath $(this))' '$(AIRY_BIN)/airyctl'
	./airy/setup -m
	./pacman/setup -m
	touch '$@'

$(tsdir)/--upgrade--:
	./pacman/update -u

defaults: clean configure
	r.airy -sd

tags:
	r.airy-cache-tags -L ~/.cache/airy/tags

tags-tree:
	tree --noreport -- ~/.cache/airy/tags | sed 's/\s*->\s*.*//'

problems:
	@echo "Manually verify necessity of packages outside of airy."
	@echo "INFO:USE:(commands): pacq, pacr, pacR, paclr"
	./airy/exe/odd-pkgs
	@echo "Merge/delete all *.pacnew files from pkg updates"
	@echo "ALT: find / -name '*.pacnew'"
	@echo "Then, for each found *.panew, do 'v -d /etc/locale.gen{,.pacnew}'"
	locate .pacnew

help:
	@echo 'Use: $(PHONY)'
	@sed -rn '/^(.*\s)?#%/s///p' '$(this)'
	$(&mods) help

#% NOTE: pass-through unknown targets as mod names
.FORCE:
%  :: .FORCE ; $(&mods) $@
%- :: .FORCE ; $(&mods) flags= $(@:-=)
