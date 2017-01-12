.DEFAULT_GOAL = open

.SUFFIXES:
.NOTPARALLEL:
.SHELLFLAGS := -euo pipefail -c
SHELL := $(shell which bash)
TMP := $(or $(TMPDIR),/tmp)/jekyll
MWD := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
export PATH := $(MWD)/bin:$(PATH)

O   ?= _build
SRC ?= site-src
CFG ?= $(SRC)/_config.yml
DST ?= gh-pages
SRV ?= http://localhost:4000


$(O) $(TMP): ; +@mkdir -p "$@"

# DEV: list all blog files or generated site as deps
# 	=> for 'serve' there is no need if using '--watch'
.PHONY: build
build: $(CFG) | $(O)
	jekyll-build "$(SRC)" "$(O)"

.PHONY: open serve invalidate
open: serve
	url-open "$(SRV)"
serve: invalidate $(TMP)/pid
invalidate:
	jekyll-invalidate "$(TMP)/pid"
$(TMP)/pid: $(CFG) | $(O) $(TMP)
	jekyll-kill "$@"
	jekyll-serve "$(SRC)" "$(O)" "$(@D)/log" > "$@"

.PHONY: publish
publish: $(DST)/.nojekyll
$(DST)/.nojekyll: $(O)/index.html | serve
	fetch-relative "$(@D)" "$(SRV)"
	touch "$@"

.PHONY: web
web: $(TMP)/url
	url-open "$$(<$<)"
$(TMP)/url: | $(TMP)
	url-hosted > "$@"

.PHONY: update
update:
	cd "$(SRC)" && bundle install
.PHONY: clean
clean:
	jekyll-kill "$@"
	rm -rf "$(O)" "$(TMP)"
.PHONY: kill
kill:
	jekyll-kill "$@"
