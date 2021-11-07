HUGO_BIN=hugo

.PHONY: upload build watch upate-theme clean

build: clean
	$(HUGO_BIN)

watch: clean
	$(HUGO_BIN) server --log

upate-theme: clean
	cd themes/hugo-coder && git checkout master && git pull --ff
	# this might be an alternative...
	#git submodule update --remote --merge

upload: build
	scp -rp ./public/ katzien.de:katzien3/

clean:
	rm -rf ./public
