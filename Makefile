HUGO_BIN=hugo

.PHONY: upload build watch upate-theme clean serve

build: clean .ensure-theme
	$(HUGO_BIN)

watch: clean .ensure-theme
	$(HUGO_BIN) serve

serve: watch

update-theme: clean .ensure-theme
	git submodule update --remote --force
	@echo "Please commit the new submodule position"
	# this might be an alternative...
	#git submodule update --remote --merge

upload: build
	rsync -rvz --partial --times  ./public/ katzien.de:katzien3/

delete-unused: build
	rsync -rvz --partial --times --delete  --dry-run  ./public/ katzien.de:katzien3/ | grep deleting

clean:
	rm -rf ./public

.ensure-theme: themes/hugo-coder/Makefile
	git submodule update
