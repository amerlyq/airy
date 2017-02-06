.NOTPARALLEL:
.DEFAULT_GOAL = default
# HACK: keep prompt unaffected  # BAD? no effect ? CHECK
#  ::: CHECK: seems like pacman isn't connected to tty despite  exec <>/dev/tty
#  <= if connected to tty -- then there must not be any pacman lines in setup.log
MAKEFLAGS += --output-sync=none

.PHONY: default
default: install

.PHONY: all
all: clean install update-new tags
.PHONY: continue
continue: update tags

# Install 'airy' config system
# BAD: no colorizing => recursive deps with r.airy-pretty
# 	=> add 'quiet' regime to linkcp
.PHONY: install
install:
	./airy/setup -m

# All choosen pkgs setup/update
# BAD: why pause at beginning of queue execution ?
.PHONY: update
update: ; r.airy -ad
.PHONY: update-new
update-new: ; r.airy -xad

.PHONY: clean
clean:
	r.airy-clean

.PHONY: log
log:
	r.airy-pretty < _build/setup.log | less -r

.PHONY: tags
tags: _build/tags
# TODO: use whole ./pkg/* instead of depending on -f ...
# ALSO: tag full ./pkg/* by content of _build/mods
# => like renaming links as 'modname' -> '[+]modname' for enabled ones
# ALT: Enabled: +mod | @mod | [+]mod, Disabled: simple name w/o marker
_build/tags: _build/mods
	r.airy-link-tags -t _build/tags -f _build/mods
