.DEFAULT_GOAL = all

.SUFFIXES:
.NOTPARALLEL:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
SHELL := $(shell which bash)
TMP := $(or $(TMPDIR),/tmp)/jekyll
MWD := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
export PATH := $(MWD)/exe:$(PATH)

O   ?= _build
SRC ?= site-src
DST ?= gh-pages
DIR ?= cfg/re/gdb
GEN ?= $(SRC)/src/mods
CFG ?= $(SRC)/_config.yml

.PHONY: all
all: clean convert build open

$(O) $(TMP) $(GEN): ; +@mkdir -p "$@"

# DEV: use all *.nou as deps to convert by mask
# 	-- by 'make' or in parallel by 'parallel'
# TRY: using 'collections' instead of 'pages'
# 	https://jekyllrb.com/docs/collections/
.PHONY: convert
convert: | $(GEN)
	nou-convert "$(DIR)" "$(firstword $|)"

# DEV: list all blog files or generated site as deps
# 	=> for 'serve' there is no need if using '--watch'
.PHONY: build
build: $(CFG) | $(O)
	jekyll-build "$(SRC)" "$(O)"

# BAD: on 'make open' doesn't rebuild by itself by '--watch'
.PHONY: open serve invalidate
open: $(TMP)/loc | serve
	url-open "$$(<"$<")"
serve: invalidate $(TMP)/pid
invalidate:
	jekyll-invalidate "$(TMP)/pid"
$(TMP)/pid: $(CFG) | $(O) $(TMP)
	jekyll-kill "$@"
	jekyll-serve "$(SRC)" "$(O)" "$(@D)/log" > "$@"

.PHONY: publish
publish: $(DST)/.nojekyll
$(DST)/.nojekyll: $(TMP)/loc $(O)/index.html | serve
	fetch-relative "$(@D)" "$$(<"$<")"
	touch "$@"

.PHONY: web
web: $(TMP)/web
	url-open "$$(<"$<")"
$(TMP)/web: | $(TMP)
	url-hosted > "$@"
$(TMP)/loc: | $(TMP)
	url-local > "$@"

.PHONY: update
update:
	cd "$(SRC)" && bundle install
.PHONY: clean
clean:
	jekyll-kill "$(TMP)/pid"
	rm -rf "$(O)" "$(TMP)" "$(GEN)/$(DIR)"
.PHONY: kill
kill:
	jekyll-kill "$(TMP)/pid"
