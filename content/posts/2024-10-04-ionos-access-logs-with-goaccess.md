---
layout: post
title: "Analysing Ionos Access logs with goaccess"
comments: True
date: "2024-10-03"
description: "Analysing access logs of an Ionos hosted static site with goaccess"
---

My domain [katzien.de](https://www.katzien.de/en/) is hosted by Ionos. They supply access logs in a subfolder of 
the account. To analyse them with [goacces](https://goaccess.io/), the following log-format and date-time arguments 
are needed:

```shell
goaccess access.log.??.? -o access.html --log-format='%h %^[%x] "%r" %s %b %v "%R" "%u" "$^" ' --datetime-format='%d/%b/%Y:%H:%M:%S %z'
```

I use the following makefile snippet to download all logs to local and analyse them:

```Makefile
download-logs:
	mkdir -p logs
	rsync -rvz --partial --times  katzien.de:logs/ ./logs/ --exclude .md5sums

analyse-logs:
	cd logs && (zcat access.log.*.gz | goaccess access.log.??.? - -o access.html --log-format='%h %^[%x] "%r" %s %b %v "%R" "%u" "$^" ' --datetime-format='%d/%b/%Y:%H:%M:%S %z')
	open logs/access.html
```

(rsync uses a host alias in `~/.ssh/config` with ssh key access...)

Of course, this made me realize that I have more malicious traffic than real read... Oh well...
