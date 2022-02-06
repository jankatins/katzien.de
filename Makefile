HUGO_BIN=hugo

.PHONY: upload build watch upate-theme clean

build: clean
	$(HUGO_BIN)

watch: clean
	$(HUGO_BIN) server --log

update-theme: clean
	cd themes/hugo-coder && git checkout main && git pull --ff
	# this might be an alternative...
	#git submodule update --remote --merge

upload: build
	rsync -rvz --partial --times  ./public/ katzien.de:katzien3/

delete-unused: build
	rsync -rvz --partial --times --delete  --dry-run  ./public/ katzien.de:katzien3/ | grep deleting

clean:
	rm -rf ./public
