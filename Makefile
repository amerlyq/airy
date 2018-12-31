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
this := $(lastword $(MAKEFILE_LIST))
$(this): ;
PHONY := $(shell sed -rn 's/^([A-Za-z0-9-]+):(\s.*|$$)/\1/p' '$(this)'|sort -u|xargs)
help: ; @echo 'Use: $(PHONY)'; sed -rn '/^(.*\s)?#%/s///p' '$(this)'
.PHONY: $(PHONY)

### Parameters
export TMPDIR      ?= /tmp/$(LOGNAME)
export AIRY_TMPDIR ?= $(TMPDIR)/airy
export AIRY_ROOT   ?= $(HOME)/.local/airy
export AIRY_BIN    ?= $(HOME)/.local/bin
export AIRY_CONFIG ?= $(or $(XDG_CONFIG_HOME),$(HOME)/.config)/airy
export AIRY_CACHE  ?= $(or $(XDG_CACHE_HOME),$(HOME)/.cache)/airy
export AIRY_DATA   ?= $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/airy

flags := -mu
&mods = +r.airy-mods-run-once "tsdir=$(AIRY_CACHE)/ts" "flags=$(flags)"

# FIXED:(r.airy): on clean install in same login
# BUG: on clean install maps "defaults" to "vi"
EDITOR ?= vi
export PATH := $(AIRY_BIN):$(PATH)

# BET:PERF: use directly $ r.airy-mods-run-once -- flags=-mu all
all: configure install setup update recache

# MAYBE: replace by "cleanup" script in each mod
#  => however, when everything is placed in ~/.cache -- there is no need to clean up ?
# TODO: rename 'recache'/'rR' to smth another to free up '-r' for general reset/remove
# IDEA: create "backup" scripts per each mod to gather all necessary data in one go
#   => so even external locations like ~/work or /data/music can be represented by private user mod ;)
#   => same as "install" -- gather list of paths by env var, but run immediately if launch
clean: ; r.airy-clean

# NOTE: prepare config system (once)
# BAD: no colorizing here => recursive deps with r.airy-pretty
# WARN: for {pacman, jobs, etc} USE >/dev/tty
# ALSO: use env vars to force $ pacman --color always $ when using TTY w/o redirect
# BAD!RFC: dirty code duplication for init (place wholesome into airy/setup)
#  => BUT: then "airy/setup" must be called even before "all/install" USE? script "init_once" ?
configure:
	mkdir -p $(dir $(AIRY_ROOT)) $(AIRY_BIN) $(AIRY_TMPDIR)
	ln -svfT $(dir $(realpath $(this))) $(AIRY_ROOT)
	ln -svfT $(realpath $(this)) $(AIRY_BIN)/r.airy
	./airy/setup -m
	./pacman/setup -m

# THINK: maybe move into separate mod "update" and place it always last
#   => PERF: allows to run "&mods" script once with argument "all" instead of staged run
# FIXME:BAD: when placed here in such inconsistent way, you can't "skip=pacman" this phase
#   => FAIL: it runs each and every time I do "make"
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
