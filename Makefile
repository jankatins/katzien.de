HUGO_BIN=hugo

.PHONY: release build watch clean

build: clean
	$(HUGO_BIN)

watch: clean
	$(HUGO_BIN) server --log

upate-theme: clean
	cd themes/hugo-coder && git checkout master && git pull --ff

upload: build
	scp -rp ./public/ katzien.de:katzien3/

clean:
	rm -rf ./public
