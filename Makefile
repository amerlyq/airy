.NOTPARALLEL:
.DEFAULT_GOAL = continue
# HACK: keep prompt unaffected  # BAD? no effect ? CHECK
#  ::: CHECK: seems like pacman isn't connected to tty despite  exec <>/dev/tty
#  <= if connected to tty -- then there must not be any pacman lines in setup.log
MAKEFLAGS += --output-sync=none

all: install update-new tags
continue: update tags
skip: next continue

# Install 'airy' config system
# BAD: no colorizing => recursive deps with r.airy-pretty
# 	=> add 'quiet' regime to linkcp
install:
	./airy/setup -m

# All choosen pkgs setup/update
# BAD: why pause at beginning of queue execution ?
update: ; r.airy -ad
update-new: ; r.airy -xad
next:
	r.airy -N

clean:
	r.airy-clean

defaults: clean install
	r.airy -sd

log:
	r.airy-pretty < _build/setup.log | less -r

tags: _build/tags
# TODO: use whole ./pkg/* instead of depending on -f ...
# ALSO: tag full ./pkg/* by content of _build/mods
# => like renaming links as 'modname' -> '[+]modname' for enabled ones
# ALT: Enabled: +mod | @mod | [+]mod, Disabled: simple name w/o marker
_build/tags: _build/mods
	r.airy-link-tags -t _build/tags -f _build/mods


TARGS := $(shell sed -rn 's/^([-a-z]+):.*/\1/p' Makefile|sort -u|xargs)
.PHONY: $(TARGS)
help:
	@echo "Use: $(TARGS)"
