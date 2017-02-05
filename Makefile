.DEFAULT_GOAL = default

.PHONY: default
default: install

# Install 'airy' config system
# BAD: no colorizing => recursive deps with r.airy-pretty
# 	=> add 'quiet' regime to linkcp
.PHONY: install
install:
	./airy/setup -m

# All choosen pkgs setup/update
.PHONY: update
update:
	r.airy -siu

.PHONY: defaults
defaults:
	r.airy-defaults

.PHONY: clean
clean:
	r.airy-clean _build

.PHONY: log
log:
	r.airy-pretty < _build/setup.log | less -r

.PHONY: tags
tags: _build/tags
_build/tags: _build/mods
	r.airy-link-tags -t _build/tags -f _build/mods
