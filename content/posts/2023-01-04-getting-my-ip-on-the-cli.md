---
layout: post
title: "What's my IP on the cli"
comments: True
date: "2023-01-04"
description: "TIL: How to get your own IP(s) on the cli via dig"
draft: false
---

I've so often googled "whats my ip" and today I was curious how to do the same on the cli. Seems that there are some DNS
servers
which [return your IP address if you ask them nicely](https://www.cyberciti.biz/faq/how-to-find-my-public-ip-address-from-command-line-on-a-linux/).
The end result is this script, which I now have as `~/bin/whatsmyip`:

```bash
#!/bin/bash
# From
# https://www.cyberciti.biz/faq/how-to-find-my-public-ip-address-from-command-line-on-a-linux/
set -e

echo "IPv4: $(dig +short txt ch whoami.cloudflare @1.0.0.1)"
echo "IPv6: $(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)"
```
    
