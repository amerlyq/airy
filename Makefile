#!/usr/bin/env -S r.airy-makelog -f
#%USAGE:
#% * (no-update): $ ./$0 flags=
#%
.DEFAULT_GOAL = all
# HACK: keep prompt unaffected  # BAD? no effect ? CHECK
#  ::: CHECK: seems like pacman isn't connected to tty despite  exec <>/dev/tty
#  <= if connected to tty -- then there must not be any pacman lines in setup.log
# MAKEFLAGS += --output-sync=none
MAKEFLAGS += --silent
.NOTPARALLEL:
.SUFFIXES:
Makefile:;
this := $(lastword $(MAKEFILE_LIST))
PHONY := $(shell sed -rn 's/^([A-Za-z0-9-]+):(\s.*|$$)/\1/p' '$(this)'|sort -u|xargs)
help: ; @echo 'Use: $(PHONY)'; @sed -rn '/^(.*\s)?#%/s///p' '$(this)'
.PHONY: $(PHONY)

### Parameters
export AIRY_ROOT   ?= $(HOME)/.local/airy
export AIRY_CONFIG ?= $(or $(XDG_CONFIG_HOME),$(HOME)/.config)/airy
export AIRY_CACHE  ?= $(or $(XDG_CACHE_HOME),$(HOME)/.cache)/airy
export AIRY_DATA   ?= $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/airy
export AIRY_BIN    ?= $(AIRY_CACHE)/bin

flags := -mu
&mods = +r.airy-mods-run-once "tsdir=$(AIRY_CACHE)/ts" "flags=$(flags)"

# FIXED:(r.airy): on clean install in same login
PATH := $(AIRY_BIN):$(PATH):$(HOME)/.local/bin
# BUG: on clean install maps "defaults" to "vi"
EDITOR ?= vi

# BET:PERF: use directly $ r.airy-mods-run-once -- flags=-mu all
all: configure install setup update recache

# MAYBE: replace by "cleanup" script in each mod
clean: ; r.airy-clean

# NOTE: prepare config system (once)
# BAD: no colorizing here => recursive deps with r.airy-pretty
# ALSO: use env vars to force $ pacman --color always $ when using TTY w/o redirect
# 	=> add 'quiet' regime to linkcp
configure:
	mkdir -p $(dir $(AIRY_ROOT))
	ln -svfT $(realpath $(dir $(this))) $(AIRY_ROOT)
	./airy/setup -m
	./pacman/setup -m

# THINK: maybe move into separate mod "update" and place it always last
#   => PERF: allows to run "&mods" script once with argument "all" instead of staged run
install:
	r.pacman-lists-install -x
	$(&mods) all/install
	r.pacman-lists-install

# MAYBE:(opt): append -B to force run of chosen target group (e.g. "setup") w/o eliminating all timestamps at once
reset: ; $(&mods) $@
setup update recache: ; $(&mods) all/$@

defaults: clean configure
	r.airy -sd

tags: _build/tags
# TODO: use whole ./pkg/* instead of depending on -f ...
# ALSO: tag full ./pkg/* by content of _build/mods
# => like renaming links as 'modname' -> '[+]modname' for enabled ones
# ALT: Enabled: +mod | @mod | [+]mod, Disabled: simple name w/o marker
_build/tags: _build/mods
	r.airy-link-tags -t "$@" -f "$<"

problems:
	@echo "Manually verify necessity of packages outside of airy."
	@echo "INFO:USE:(commands): pacq, pacr, pacR, paclr"
	./airy/exe/odd-pkgs
	@echo "Merge/delete all *.pacnew files from pkg updates"
	@echo "ALT: find / -name '*.pacnew'"
	@echo "Then, for each found *.panew, do 'v -d /etc/locale.gen{,.pacnew}'"
	locate .pacnew

#% NOTE: pass-through unknown targets as mod names
.FORCE:
%  :: .FORCE ; $(&mods) $@
%- :: .FORCE ; $(&mods) flags= $(@:-=)
