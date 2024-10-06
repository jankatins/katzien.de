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

download-logs:
	mkdir -p logs
	rsync -rvz --partial --times  katzien.de:logs/ ./logs/ --exclude .md5sums

# 78.46.70.0 - - [06/Oct/2024:00:00:23 +0200] "HEAD /en/posts/2024-10-03-azure-vpn-under-fedora/ HTTP/1.1" 200 - www.katzien.de "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36" "-"
#174.138.22.0 - - [06/Oct/2024:01:29:55 +0200] "GET /media/wp-includes/wlwmanifest.xml HTTP/1.1" 404 1271 katzien.de "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36" "-"
analyse-logs:
	cd logs && (zcat access.log.*.gz | goaccess access.log.??.? - -o access.html --log-format='%h %^[%x] "%r" %s %b %v "%R" "%u" "$^" ' --datetime-format='%d/%b/%Y:%H:%M:%S %z')
	open logs/access.html


