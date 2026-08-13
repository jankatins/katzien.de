# The default target
.DEFAULT_GOAL := help

SHELL := /bin/bash
ifndef VERBOSE
# On linux, do not print the enter/exit directory messages
MAKEFLAGS += --no-print-directory
endif

ifeq ($(OS),Windows_NT)
    uname_S := Windows
else
    uname_S := $(shell uname -s)
endif

ifeq ($(uname_S), Windows)
    OPEN = start
else ifeq ($(uname_S), Linux)
    OPEN = xdg-open
else ifeq ($(uname_S), Darwin)
    OPEN = open
endif

HUGO_BIN=hugo

.PHONY: build
build: clean themes/hugo-coder/Makefile ## Build the website into the ./public folder
	$(HUGO_BIN)
	cp public/en/404.html public/404.html

.PHONY: .hugo-serve
.hugo-serve: clean themes/hugo-coder/Makefile
	$(HUGO_BIN) serve

.PHONY: .open-in-browser
.open-in-browser:
	@sleep 2
	$(OPEN) http://localhost:1313/

.PHONY: serve
serve: ## Serve the website from local
	make -j .hugo-serve .open-in-browser

# from https://www.cyberdemon.org/2024/03/20/submodules.html
.PHONY: update-theme
update-theme: clean themes/hugo-coder/Makefile ## Update the theme
	cd themes/hugo-coder && git pull origin main
	@printf "\n!!! Please commit the new submodule position if it changed !!!\n"

# from https://www.cyberdemon.org/2024/03/20/submodules.html
themes/hugo-coder/Makefile:
	git submodule update --init --recursive


.PHONY: upload
upload: build ## Upload generated files
	rsync -rvz --partial --times  ./public/ katzien.de:katzien3/

.PHONY: delete-unused
delete-unused: build ## Delete unused files in ftp site
	rsync -rvz --partial --times --delete  --dry-run  ./public/ katzien.de:katzien3/ | grep deleting

.PHONY: clean
clean: ## Clean up generated files
	rm -rf ./public


.PHONY: download-logs
download-logs: ## Download logs
	mkdir -p logs
	rsync -rvz --partial --times  katzien.de:logs/ ./logs/ --exclude .md5sums

# 78.46.70.0 - - [06/Oct/2024:00:00:23 +0200] "HEAD /en/posts/2024-10-03-azure-vpn-under-fedora/ HTTP/1.1" 200 - www.katzien.de "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36" "-"
#174.138.22.0 - - [06/Oct/2024:01:29:55 +0200] "GET /media/wp-includes/wlwmanifest.xml HTTP/1.1" 404 1271 katzien.de "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36" "-"
.PHONY: analyse-logs
analyse-logs: ## Analyse logs
	cd logs && (zcat access.log.*.gz | goaccess access.log.??.? - -o access.html --log-format='%h %^[%x] "%r" %s %b %v "%R" "%u" "$^" ' --datetime-format='%d/%b/%Y:%H:%M:%S %z')
	$(OPEN) logs/access.html

MARKDOWN_SOURCE_FILES ?= $(shell git ls-files --others --modified --cached -- "*.md")
EN_MARKDOWN_SOURCE_FILES ?= $(shell git ls-files --others --modified --cached -- "*.md" ":!:*.de.md")

.PHONY: format-md
format-md: ## Format all git-known markdown
	rumdl fmt $(MARKDOWN_SOURCE_FILES)

.PHONY: fix-typos
fix-typos: ## Fix spelling errors with typos (only EN markdown!)
	typos --write-changes $(EN_MARKDOWN_SOURCE_FILES)

.PHONY: help
help:     ## Show this help
	@grep -E -h '\s##\s' $(MAKEFILE_LIST) | grep -v "^#.*" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'
