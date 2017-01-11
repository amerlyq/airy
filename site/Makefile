.SUFFIXES:
.NOTPARALLEL:
.DEFAULT_GOAL = build
.SHELLFLAGS := -euo pipefail -c
SHELL := $(shell which bash)

PWD := $(shell pwd)
O   ?= _build
SRC ?= site-src
DST ?= $(PWD)/gh-pages
JKL := bundle exec jekyll
PID := $(O)/jekyll.pid
LOG := $(O)/jekyll.log


$(O): ; +@mkdir -p "$@"

# NOTE: pwd must contain Gemfile
# MAYBE: keep Gemfile inside gh-pages trash ?
.PHONY: build
build: $(SRC)/_config.yml | $(DST)
	cd "$(SRC)" && $(JKL) build -d "$(firstword $|)"  # -V



# => Use `--no-watch` to disable auto-regeneration.
$(PID): $(SRC)/_config.yml | $(DST) $(O)
	$(MAKE) --no-print-directory kill
	(cd "$(SRC)" && $(JKL) serve -d "$(firstword $|)" \
	  --skip-initial-build --watch --detach \
	) > "$(LOG)"
	sed -rn "6s/.*with pid '([0-9]+)'.*/\1/p" "$(LOG)" > "$@"

.PHONY: kill
kill:
	@pkill -F "$(PID)" &>/dev/null || true
	@rm -f "$(PID)"

.PHONY: serve
serve: $(PID)
	pgrep -F "$<" >/dev/null || \
	  { rm -f "$<"; $(MAKE) --no-print-directory "$<"; }

# TODO: sync lock to concrete window (until exited)
.PHONY: run
run: serve
	r.b http://localhost:4000 2>/dev/null



$(O)/web.url: | $(O)
	git remote get-url origin \
	  | sed -r 's|^.*:([^/]+)/(.*)|https://\1.github.io/\2|' \
	  > "$@"

.PHONY: web
web: $(O)/web.url
	r.b "$$(<$<)" 2>/dev/null
