---
layout: post
title: "Python development on Windows: making it comfortable"
comments: True
date: "2016-01-26"
---

Recently someone was surprised that I use windows as my main dev machine as other OS usually are developer friendly. Out of the box, this is true. But to make yourself at home as a developer, you usually change a lot of things, no matter if you are using OS X, Linux or Win. So here is what I use:

* proper command line: cmder with git
* Pycharm + Notepad++ as editor
* python from miniconda with multiple envs
* jupyter notebook with a conda env kernel manager

Not all is windows specific... I actually suspect that a lot is windows agnostic and I would use a similar setup on a different OS... 

### A proper command line: cmder

Windows `cmd` is pretty limited, both because there is almost no commands available and because of the terminal window itself lacks tab competition, history, proper C&P... I use [cmder](https://github.com/cmderdev/cmder) as a replacement. Use the upcoming 1.3 version, it changes the way the config / startup files are handled -> available as an artifact in the Appveyor builds (e.g. [this one](https://ci.appveyor.com/project/MartiUK/cmder/build/artifacts)). It comes with better tab completion (including for git commands), history, search previous commands, c&p, git integration in the prompt, and can be customized via a startup profile. It also includes a copy of git for windows 2.x, so for most case, there is no need to install git by yourself. You can use cmd, bash (comes with the copy of git) and powershell.

I install it in a dropbox subfolder, which means that I have the same environment even at work. Run `cmder.exe /REGISTER ALL` once as admin to get the `cmder here` item in the right click menu in windows explorer.

In `config\user-profile.cmd`, I add a few more path items and also start an ssh agent:

```batch
:: needs the private ssh key in %USERPROFILE%\.ssh\
@call start-ssh-agent

:: add my own scripts
@set "PATH=%PATH%;%CMDER_ROOT%\vendor\jasc"

:: add unix commands from existing git -> last to not shadow windows commands...
@set "PATH=%PATH%;%GIT_INSTALL_ROOT%\usr\bin\"
```

Thanks to the last line, I've `ls`, `grep`, `find`, `ssh`, ... available in the command line.

Aliases are in `config\aliases`. I add things like

```
w=where $1
cdp=cd c:\data\external\projects 
ls_envs=ls c:\portabel\miniconda\envs\
note="C:\Program Files (x86)\Notepad++\notepad++.exe" $*
```

I also customize the prompt (via a `config/conda.lua` file) so that activating a conda env will show up in the prompt (The need for the reset is [IMO a bug](https://github.com/cmderdev/cmder/issues/749)):

```lua
---
 -- Find out the basename of a file/directory (last element after \ or /
 -- @return {basename}
---
function basename(inputstr)
        sep = "\\/"
        local last = nil
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                --t[i] = str
                --i = i + 1
                last = str
        end
        return last
end

---
 -- Find out if the String starts with Start
 -- @return {boolean}
---
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

---
 -- Find out current conda env
 -- @return {false|conda env name}
---
function get_conda_env()
    env_path = clink.get_env('CONDA_DEFAULT_ENV')
    if env_path then
        basen = basename(env_path)
        return basen
    end
    return false
end

---
 -- after conda activate: reset prompt 
---
function reset_prompt_filter()
    -- reset to original, e.g. after conda activate destroyed it...
    if string.match(clink.prompt.value, "{lamb}") == nil or not string.starts(clink.prompt.value,"\x1b[") then
        -- orig: $E[1;32;40m$P$S{git}{hg}$S$_$E[1;30;40m{lamb}$S$E[0m
        -- color codes: "\x1b[1;37;40m"
        cwd = clink.get_cwd()
        prompt = "\x1b[1;32;40m{cwd} {git}{hg} \n\x1b[1;30;40m{lamb} \x1b[0m"
        new_value = string.gsub(prompt, "{cwd}", cwd)
        clink.prompt.value = new_value
    end
end

---
 -- add conda env name 
---
function conda_prompt_filter()
    -- add in conda env name
    local conda_env = get_conda_env()
    if conda_env then
        clink.prompt.value = string.gsub(clink.prompt.value, "{lamb}", "["..conda_env.."] {lamb}")
    end
end

clink.prompt.register_filter(reset_prompt_filter, 10)
clink.prompt.register_filter(conda_prompt_filter, 20)


local function tilde_match (text, f, l)
    if text == '~' then
        clink.add_match(clink.get_env('userprofile'))
        clink.matches_are_files()
        return true
    end
end

clink.register_match_generator(tilde_match, 1)
```


### git setup

I usually add two remotes: the upstream repo as `origin` (using the https URL for `git clone`) and my fork as `mine` (using the ssh URL for `git remote add mine <ssh-url>`). I do that even in cases where I am the upstream. 

`mine` is setup as the default remote push location and `git push` defaults to the current branch. That way I can do things like `git push` without specifying a remote or without getting a confirmation message on first push of a branch. 

Thanks to the ssh agent started by cmder on startup, I only have to give my password once per session.

I've setup notepad as the git commit editor but probably will switch to Sublime Text because of the better spell checking...

The following are the relevant lines of my `%USERPROFILE%\.gitconfig`:

```
[...]
[core]
	editor = \"C:\\Program Files (x86)\\Notepad++\\notepad++.exe\"  -multiInst -nosession -noPlugin
	excludesfile = ~/.gitignore-global # for things like the .idea dir from pycharm
[push]
	# don't show a setup message on first push of the branch
	default = current
[remote]
	# per default push to "mine"
	pushdefault = mine
[alias]
	unadd = reset HEAD --
    fixup = commit --amend --no-edit
	slog = log --pretty=oneline --abbrev-commit
    dc = diff --cached
    # specially for word files which are shown as text in the latest git for windows 2.x builds
    wd = diff --word-diff

```

I also install [git-extras](https://github.com/tj/git-extras/blob/master/Commands.md), mainly for `git pr` (checkout a github PR directly from origin), `git ignore`, `git changelog`

### Python development: editors, conda

#### Editors: Pycharm, Notepad++, Sublime Text 3
I mainly use a combination of [Pycharm](https://www.jetbrains.com/pycharm/) (IDE for bigger projects/changes), [Notepad++](https://notepad-plus-plus.org/) (small patches, build related stuff) and recently [Sublime Text 3](https://www.sublimetext.com/3) (replacement for notepad++, lets see...). Notepad++ is setup to [replace notepad.exe](http://www.binaryfortress.com/NotepadReplacer/), so anything which calls notepad will bring up Notepad++. Other than that, I use no special config for the IDE/editors...

#### conda python
I currently use a [miniconda py27](http://conda.pydata.org/miniconda.html) setup (which I should update to a py3.x based one, but am too lazy...), but use envs for most of the work (e.g. the main env has mostly only conda + conda build related stuff in it). The default env is added to the default path (either by the installer or by using `setx path C:\portabel\miniconda;C:\portabel\miniconda\Scripts;%PATH%` in a cmd, not cmder window). I create additional envs with `conda create -n <env-name> python=x.x pandas matplotlib ...` as needed. Pycharm can use envs as additional interpreters, so no problem there... On the command line, thanks to the above cmder setup, an `ls_envs` will show all environments and `activate <env-name>` works without problems and the conda env name is shown in the command line.

I installed the visual studio compilers for 2.7, 3.4 and 3.5 by *religiously* following the following blog post on ["Compiling Python extensions on Windows"](http://blog.ionelmc.ro/2014/12/21/compiling-python-extensions-on-windows/) by [@ionelmc](https://twitter.com/ionelmc). It works!

If conda has no package for the package you want, activate the env, `conda install pip` and then use pip to install the package into that env. `conda list` shows both conda packages and pip packages.

### Jupyter notebook

I have one "jupyter-notebook" env which holds the install for the notebook (e.g. `conda create -n jupyter-notebook python=3.5 notebook`). I start notebook servers via shortcuts, which point to the `jupyter-notebook.exe` entry in the `jupyter-notebook` env (e.g. `C:\portabel\miniconda\envs\jupyter-notebook\Scripts\jupyter-notebook.exe`) and which are setup to start in the main project directory (e.g. `c:\data\external\projects\projectA\`). That way I can startup multiple notebook servers in different project dirs by using multiple shortcuts.

#### Add all conda envs as kernels

I use [Cadair/jupyter_environment_kernels](https://github.com/Cadair/jupyter_environment_kernels/) (with an additional [PR](https://github.com/Cadair/jupyter_environment_kernels/pull/6)) as a kernel manager, so all my conda environments show up as additional kernel entries. For each project, I setup a new conda environment which is then used in the project notebooks as kernel.

#### Add-ons for jupyter notebook

I install the [jupyter notebook extensions](https://github.com/ipython-contrib/IPython-notebook-extensions) (installed in the `jupyter-notebook` conda environment), mainly for the Table of Content support.

I also add some ipython magic commands to each python environment which is used as notebook kernel:

* [IPython-extensions](https://github.com/ipython-contrib/IPython-extensions): for `%%inactive` (don't execute a cell in e.g. a "Run all Cells") and `%%writeandexecute` (enable [code reuse from one notebook to another](https://ipython-extensions.readthedocs.org/en/latest/magics.html#cellmagic-writeandexecute)).
* [watermark](https://github.com/rasbt/watermark): for `%watermark`, which outputs some version information to make notebooks reproducible. 

#### proper diffs and commits for notebooks

I usually don't want to commit the outputs of a notebook to git, so I strip them with a [git clean filter](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes#Keyword-Expansion). 

I also want `git diff` to show something which I can actually read instead of the raw json file content, so I also setup a special converter which is [used by git diff before comparing the files](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes). 

There are a lot of scripts around for that, but most use python (e.g. strip output ([gist](https://gist.github.com/minrk/6176788), [kynan/nbstripout](https://github.com/kynan/nbstripout)) and [nbflatten](https://gist.github.com/takluyver/bc8f3275c7d34abb68bf) but this is slow for big notebooks. :-(  Fortunately, the nbflatten gist also introduced me to [jq](https://github.com/stedolan/jq), something like grep and sed/awk for json data. After sorting out a [windows bug](https://github.com/stedolan/jq/issues/1072), this [jq based nbflatten script](https://gist.github.com/jfeist/cd00aa3b681092e1d5dc) now works on windows, too. Below is a slightly adjusted variant of that script.

This needs a recent [jq.exe](https://github.com/stedolan/jq) (>=1.6, not yet released, go to https://ci.appveyor.com/project/stedolan/jq and click on one of the passing builds -> 64bit -> ARTIFACTS) due to a [bug](https://github.com/stedolan/jq/issues/1072) in 1.5. Put `jq.exe` in your path (e.g. `<cmder>\bin`) and add the following file somewhere:

```
# based on https://gist.github.com/jfeist/cd00aa3b681092e1d5dc
def banner: "\(.) " + (28-(.|length))*"-";
# metadata
("Non-cell info" | banner), del(.cells), "",
# content
(.cells[] | (
     ("\(.cell_type) cell" | banner), 
     (.source[] | rtrimstr("\n")), # output source
     if ($show_output == "1") then # the cell output only when it is requested..
       "",
       (select(.cell_type=="code" and (.outputs|length)>0) | (
         ("output" | banner),
         (.outputs[] | (
            (select(.text) | "\(.text|add)" | rtrimstr("\n")),
            (select(.traceback) | (.traceback|join("\n"))),
            (select(.text or .traceback|not) | "(Non-plaintext output)")
		   )
         ),
         ""
		)
       )
     else 
       ""
     end
  )
)
```

I put mine as `nbflatten.jq` into a cmder subdir.

I now have the following in my global `.gitconfig`:

```
[filter "stripoutput"]
	# removes output and execution counts form the notebook before committing it
    clean = "jq --indent 1 '(.cells[] | select(has(\"outputs\")) | .outputs) = [] | (.cells[] | select(has(\"execution_count\")) | .execution_count) = null'"
[diff "ipynb"]
	# uses a "flattend" representation of the notebook for diffing
	# note the quotes and the escapes for the quotes around the filename and the backslashes...
    textconv = "jq -r -f \"C:\\Users\\jschulz\\Dropbox\\Programme\\cmder\\vendor\\jasc\\nbflatten.jq\" --arg show_output 0"
    cachetextconv = false
```

If I have notebooks in a repo which I want cleaned up before committing and/or diffing, I add a `.gitattribute` file with the following content:

```
*.ipynb filter=stripoutput
*.ipynb diff=ipynb
```

Please note that both together mean that the `ipynb` `git diff` engine never sees the output in a notebook (as the filter is run before the diff), so most of the above `nbflatten.jq` file is useless in that case (and even without the filter it would still not show up until you change "show_output 0" to "show_output 1") . But you can use it via an alias (in `<cmder>\config\aliases`) ala

```
nbflat=jq -r -f "C:\Users\jschulz\Dropbox\Programme\cmder\vendor\jasc\nbflatten.jq" --arg show_output 1 $*
```

and then use it like `nbflat whatever.ipynb | less` to get a text representation.

#### nbconvert

I installed nbconvert into the main conda env: `deactivate & conda install nbconvert`

For pdf output, I installed miktex and pandoc:

* [miktex](http://miktex.org/portable): latex environment. Installed via the portable installer and added to the path (via `setx path c:\path\to\MIKTEX\miktex\bin;%path%` in a cmd window, not cmder -> that way you have latex available in all programs and not only in a cmder window).
* [pandoc](http://pandoc.org/installing.html): converter between text formats (e.g. markdown to word or pdf). Also added to the path like miktex. 

It has to go to the main path (not setup via cmder), as the way I startup a notebook server does not get the path additions from cmder...

### Other stuff

* [everything](https://www.voidtools.com/): search for filenames (not content). Installed as a service and then put [`es.exe`](https://www.voidtools.com/downloads/) in a dir in `%PATH%` (e.g. `<cmder>\bin`). `es whatever.py` will now show all files with that name.
* [launchy](http://www.launchy.net/): search and startup commands fast. Faster than `Start-><search box>-><Enter>`... I used that much more when I had WinXP installed. Nowadays, I have most programs added as a shortcut to the quickstart area.
* Chrome with [ublock](https://www.ublock.org/) (ad blocking) and [The Great Suspender](https://chrome.google.com/webstore/detail/the-great-suspender/klbibkeccnjlkjkiokjodocebajanakg) (suspend tabs which you haven't touched in days so that they don't waste resources).
* [sysinternals](https://technet.microsoft.com/en-us/sysinternals/bb545021.aspx): `procexplorer` (graphical process explorer, replacement for the task manager). Setup to [start as admin](https://technet.microsoft.com/en-us/magazine/ff431742.aspx) during windows startup. I also use `autostarts` from time to time to clean up the autostart entries. 
* [Keepass 2](http://keepass.info/): holds all my passwords, integrated with chrome via [chromeIPass](https://chrome.google.com/webstore/detail/chromeipass/ompiailgknfdndiefoaoiligalphfdae). The keepass file is synced via dropbox to my [mobile](https://play.google.com/store/apps/details?id=keepass2android.keepass2android) (+ a keyfile which is manually transfered...). 


###  final remarks

So, you can make yourself at home on windows as a (python) developer... Unfortunately, it seems that there are not a lot of people who do dev work on windows (based on the many projects which fail on windows when I check them out). If you want to make your project windows friendly: add Appveyor to your CI tests... :-)

Anyway: anything I missed to make my life on windows any easier?