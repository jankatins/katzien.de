---
layout: post
title: "Automatic building of python wheels and conda packages"
comments: True
date: "2015-10-22"
---

Recently I found the [conda-forge](https://github.com/conda-forge/) project on github which makes it easy to auto build and upload your python project as a (native) conda package. Conda-forge introduces the concept of a "smithy" (a repository on github) which builds the conda packages for the main repository. A smithy connects to three different CI services to get builds for all three major platforms: Travis for Mac OS X, CircleCI for Linux and AppVeyor for Windows.

But not everyone is using conda environments so I thought it would be nice to to also build wheels with it. Turns out this is actually possible, you "only" need to hack the conda build scripts to also build a wheel and upload that to PyPI.

For those who just want the code: you can find it in the [JanSchulz/package-builder repo on github](https://github.com/JanSchulz/package-builder). The smithy currently builds the [conda packages](https://anaconda.org/janschulz/pypandoc/files) and [wheels](https://pypi.python.org/pypi/pypandoc/) for [pypandoc](https://github.com/bebraw/pypandoc/). PRs welcome :-)

These were the broad steps to setup the smithy:

* Setup a smithy repository: I copied the [conda-forge/staged-recipes](https://github.com/conda-forge/staged-recipes), which is setup to build multiple recipes, but required a little more "handholding" until I got it to run (the "one main repo, one smithy repo" case has helper scripts in [conda-forge/conda-smithy](https://github.com/conda-forge/conda-smithy), which will make the setup of the smithy a lot easier. So try that first if that fits your case...): 
  * Add your own conda recipe: it's usually three easy files in a subdir: one metadata file (`meta.yaml`) and one script for each windows (`bld.bat`) and unix-like platforms (`build.sh`). Take a look at some [examples](https://github.com/conda/conda-recipes)...
  * Connect the various CI services to your github repo.
  * Get your anaconda access TOKEN via `anaconda auth --create --name WhateverName --scopes "repos conda api"` (I used a different token for each CI service). The examples in the [conda-forge/staged-recipes](https://github.com/conda-forge/staged-recipes) files didn't quite work, as I needed to add `api` access...
  * Add your anaconda access TOKEN to each CI service so that it is available in your build environment. 
* Hack your conda recipe to also build a wheel and upload that to PyPI. This is a bit more involved, as conda builds happen in a temporary environment and have their environment variables cleaned up. So:
  * Install twine in the environment, by adding `pip install twine` to the various CI setup scripts (unfortunately it's not packaged for conda, so you can't simple install it via `meta.yaml`).
  * Add your PyPI username and password as a environment variable to each CI service.
  * Let `conda build` know that you want to have these two variables available during the conda build by [adding them to the `build -> script_env` section](http://conda.pydata.org/docs/building/environment-vars.html#inherited-environment-variables) of your `meta.yaml`.
  * Add a line to your build scripts to build a wheel (`python setup.py bdist_wheel`).
  * Generate a `pypirc` file so that the PyPI upload can happen. This is a bit tricky, as the build process has no access to the recipe directory and therefore you have to generate this file on the fly during build. On unix-like it's a `cat << EOF > pypirc\n...\nEOF`, but on windows you have to use either a lot of `echo ... >>pypirc` or a trick with parenthesis: `( echo ...; echo ... ...)  > "pypirc"`. It seems that twine [doesn't work without such a file](https://github.com/pypa/twine/issues/143) :-(.
  * Use twine to upload the package: this [currently means that you have to add a username and password (using the added environment variables) to the commandline](https://github.com/pypa/twine/issues/144), so make sure that this line isn't echo'ed to the CI log: use `@twine ...` in `bld.bat` and `set +x; twine ...; set -x` in `build.sh`.
  * I also added a test to `build.sh` to only build wheels on darwin, as it seems that PyPI does not accept linux wheels...
* Fix all the errors you introduced and repush the repo... this step took a bit... :-/
  
Now making a release works like this:

* Release the package (in my case [pypandoc](https://github.com/bebraw/pypandoc/)) as usual.
* Build and upload the `sdist` to PyPI.
* Update the conda recipe for the new version.
* Push the smithy repo with the recipe and let the CI services build the conda packages and the wheels.

The CI scripts will only build packages for which there are no current conda packages yet. If you need to redo the build because of some problems, you need to delete the conda packages for the affected builds or bump the package versions (you can set build versions for the conda packages without bumping the version of the upstream project).

If you have any feedback, please leave it in the comments (or as an issue in one of the above repos... :-) ).
  
The next step will be [adding builds for R packages](https://github.com/IRkernel/irkernel.github.io/issues/16)...