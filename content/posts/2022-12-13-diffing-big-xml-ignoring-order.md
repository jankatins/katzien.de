---
layout: post
title: "Diffing XML and ignoring element and attribute order"
comments: True
date: "2022-12-13"
description: "TIL: way to diff xml content (ignoring element and attribute order) with even big XML files"
---

At work, I had the need to get a biggish (65MB) XML file into a DB and out again. To check that this all worked, I
wanted to compare the two xml files. For this comparison, it didn't matter in which order the elements and attributes
were, just that all of them were there in the same way as before. The main problem was that the XML file was ~65MB big.

Some xml diff programs I found on the net took more than a night (didn't wait for them to finish).
Stackoverflow had some
ideas [how to diff xml files and ignore attribute order, but not element order.](https://superuser.com/questions/79920/how-can-i-diff-two-xml-files)
Given that I didn't want a readable diff, just some confirmation that the file content was the same, I settled for this
pipeline:

1. Make a canonical XML all attributes are in the same order
2. Pretty print it so there is one element per line and the indention is the same
3. Sort it
4. Diff the sorted xml

Here is a makefile snippet to do it and show the top 30 lines of the diff:

```Makefile
# Prepare the original file
tmp/orig_sorted.xml: data/orig.xml
	mkdir -p tmp/
	xmllint --exc-c14n data/orig.xml | xmllint --format /dev/stdin | sort  > tmp/orig_sorted.xml

.PHONY: test-export
test-export: tmp/orig_sorted.xml
	do-export -o exports/whatever.xml
	xmllint --exc-c14n  exports/whatever.xml | xmllint --format /dev/stdin | sort  > tmp/whatever_sorted.xml
	diff -u --speed-large-files  tmp/orig_sorted.xml tmp/whatever_sorted.xml > tmp/diff.txt || true
	head -n 30 tmp/diff.txt
```
