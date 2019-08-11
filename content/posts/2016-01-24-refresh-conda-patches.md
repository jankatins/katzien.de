---
layout: post
title: "How to refresh conda patches"
comments: True
date: "2016-01-24"
---

Conda recipes can contain patches which are applied on top of the source for the package. When updating the package to a new upstream version, these patches need to be checked if the still apply (or are still needed).

This is the way I do it currently (be aware that I work on windows, so you might need to change some slashes...)...

## Preparation


```bash
# makes the "patch" command available...
set "PATH=%path%;C:\Program Files\Git\usr\bin\"
# Update the latest source for matplotlib...
cd matplotlib 
git fetch 
git checkout origin/master
# conda package recipe for matplotlib is in ci\conda_recipe
```

## Apply a patch

```
patch -i ci\conda_recipe\osx-tk.patch
```

The next step depends whether the patch applied cleanly or not. There are three possible outcomes:

* The patch applied cleanly (e.g. no error message): nothing further to do, on to the next patch... 
* The patch is fuzzy (`Hunk #1 succeeded at 1659 with fuzz 1 (offset 325 lines).`) -> the patch only needs to be refreshed
* The patch (or one of the hunks) didn't apply (`1 out of 1 hunk FAILED -- saving rejects to file matplotlibrc.template.rej`) -> the patch needs to be redone and afterwards the patch needs to be refreshed

For redoing the patch, look into the `<patch>.rej` file and apply similar changes to the source. Or check whether this patch is needed anymore...

For refreshing the patch, make sure that only the changes for the patch are currently included in you checked out copy (e.g. make sure that refreshed patches are `git add`ed before the next command...). 

Then run the following command:

```
git diff --no-prefix > ci\conda_recipe\osx-tk.patch
```

[I actually used a different filename to pipe the patch to and then compared the output before overwriting the old patch...]
