HUGO_BIN=hugo

.PHONY: upload build watch upate-theme clean serve

build: clean themes/hugo-coder/Makefile
	$(HUGO_BIN)

watch: clean themes/hugo-coder/Makefile
	$(HUGO_BIN) serve

serve: watch

update-theme: clean themes/hugo-coder/Makefile
	git submodule update --remote --force
	# this might be an alternative...
	#git submodule update --remote --merge
	@printf "\n!!! Please commit the new submodule position !!!\n"

upload: build
	rsync -rvz --partial --times  ./public/ katzien.de:katzien3/

delete-unused: build
	rsync -rvz --partial --times --delete  --dry-run  ./public/ katzien.de:katzien3/ | grep deleting

clean:
	rm -rf ./public

themes/hugo-coder/Makefile:
	git submodule update --init --recursive
