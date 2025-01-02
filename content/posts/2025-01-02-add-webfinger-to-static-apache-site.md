---
layout: post
title: "Add webfinger to a static apache hosted site to be discoverable from mastodon"
comments: True
date: "2025-01-02"
description: "add webfinger to a hugo site hosted on a apache webserver to be findable from mastodon"
---

[Webfinger](https://en.wikipedia.org/wiki/WebFinger) is a protocol to get information about a user. It's used for
[discoverability in mastodon](https://docs.joinmastodon.org/spec/webfinger/): search for an email "jan@katzien.de"
on your home instance (you must be logged in for this to work!) and mastodon will query
`/.well-known/webfinger?resource=acct:jan@katzien.de` on `katzien.de` to look up
information about me and my mastodon profile.

There are a [few](https://blog.maartenballiauw.be/post/2022/11/05/mastodon-own-donain-without-hosting-server.html)
[pages](https://blog.maartenballiauw.be/post/2022/11/05/mastodon-own-donain-without-hosting-server.html) which
describe how to do it for a static page on your own static website: you dump the content of that URL on your mastodon
home instance (e.g. in my case
[https://fosstodon.org/.well-known/webfinger?resource=acct:jankatins@fosstodon.org](https://fosstodon.org/.well-known/webfinger?resource=acct:jankatins@fosstodon.org))
into a file `.well-known/webfinger` and your server will serve that. But doing it this way will not take the query
parameters into account, creating in essence a catch-all address: all emails will map to that one webfinger content.
I don't want that, but I also don't want to use a php script or something similar to the site to serve different
content per query parameter.

So here is a way to solve it using `mod_rewrite` if you are hosting your domain on an apache server:

You need three files:

- `.well-known/.htaccess` -> to instruct the apache server to serve specific content per query parameter
- `.well-known/webfinger.name__domain.tld` (In my case `.well-known/webfinger.jan__katzien.de`) -> the webfinger
  content which should be served when requesting `/.well-known/webfinger?resource=acct:jan@katzien.de` (copied from
  my mastodon host)
- `.well-known/webfinger` -> empty file, no idea why it was necessary, but mod_rewrite refused to work without
  this :-(

`.well-known/.htaccess`:

```.htacces
# The 404 file which should be served, if a webfinger account is not found: in my case the one in the root directory
ErrorDocument 404 /404.html

# Prevent directory listings and helpful typo corrections -> these would show all webfinger enabled accounts :-(
Options -Indexes
Options -MultiViews
CheckSpelling off

# Use mod_rewrite for fetching the right webfinger content
RewriteEngine On
RewriteBase /.well-known/

# /.well-known/webfinger?resource=acct%3Ajan%40ekatzien.de
# /.well-known/webfinger?resource=acct:jan@katzien.de
RewriteCond %{QUERY_STRING}  ^resource=acct(:|%3A)([A-Za-z0-9\.\-\+]+)(@|%40)([A-Za-z0-9\.\-]+)$ [NC]
RewriteRule webfinger webfinger.%2__%4 [NE,E=is_webfinger:true,L]
Header set Content-Type application/jrd+json env=is_webfinger

# Make sure everything else on /.well-known/webfinger returns a 404
RewriteRule webfinger - [R=404,L]
```

`.well-known/webfinger.jan__katzien.de`
```json
{
  "subject": "acct:jankatins@fosstodon.org",
  "aliases": [
    "https://fosstodon.org/@jankatins",
    "https://fosstodon.org/users/jankatins"
  ],
  "links": [
    {
      "rel": "http://webfinger.net/rel/profile-page",
      "type": "text/html",
      "href": "https://fosstodon.org/@jankatins"
    },
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://fosstodon.org/users/jankatins"
    },
    {
      "rel": "http://ostatus.org/schema/1.0/subscribe",
      "template": "https://fosstodon.org/authorize_interaction?uri={uri}"
    },
    {
      "rel": "http://webfinger.net/rel/avatar",
      "type": "image/jpeg",
      "href": "https://cdn.fosstodon.org/accounts/avatars/109/293/240/334/508/299/original/fc7031afafd6bba2.jpeg"
    }
  ]
}
```

As I use hugo, I dumpted this into `static/.well-known/` to be included in the site.

You can test that it works via

```shell
λ curl -v -X GET \
  -H "Accept: application/jrd+json" \
  -H "Content-Type: application/json" \
   "https://katzien.de/.well-known/webfinger?resource=acct:jan@katzien.de"

...
< HTTP/2 200
< content-type: application/jrd+json
...
{
    "subject": "acct:jankatins@fosstodon.org",
    ...
}
```

Also make sure that all unknown emails return 404:

```shell
λ curl -v -X GET \
  -H "Accept: application/jrd+json" \
  -H "Content-Type: application/json" \
   "https://katzien.de/.well-known/webfinger?resource=acct:not.existing@katzien.de"

...
< HTTP/2 404
...
```

Now you can search for `jan@katzien.de` on a mastodon instance (as long as you are logged in), and you will find my
mastodon profile:

![Search for my name on my maston instance](/uploads/2025/2025-01-02-add-webfinger-to-static-apache-site-1.png)
