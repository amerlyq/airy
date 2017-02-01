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
