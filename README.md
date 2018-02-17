# MSYS2 in Wine in docker experiments

Big thanks to @fracting and https://github.com/TeaCI/msys2-docker for figuring
out how to get MSYS2 in Wine in an Ubuntu 14.04 docker. Without this, I would
have been hopeless

https://github.com/fracting/wine-fracting/wiki/MSYS2-on-Wine
https://github.com/TeaCI/tea-ci/wiki/Msys2-on-Wine

## TL;DR

```
docker-compose run -e USER_ID=`id -u` wine
```

## Motivation

- The [original repo](https://github.com/TeaCI/msys2-docker) is sort of out
of date and cannot be reproduced using just the git repo. And only works on
Ubuntu 14 in a very special configuration. While little progress has been
made into solving the main cygwin core v2.6 in wine, I wanted to reproduce
this work, and update where possible.

- Even the links to the bugs that the TeaCI docker fixes no longer work. Thanks
wine!

- There was a lack of documentation. Like knowing you need to run `--privileged`,
and actually knowing you just need to run `--cap-add=SYS_PTRACE` and the way they
had it set up, `xhost +`, etc... There was no readme to help with that


## Objectives

1. Get this working in something other than Ubuntu 14.04 - *Mostly failed*
1. Get this working with a modern build - **Success**
1. Get this working without `xhost +` and `--privileged` - **Success**
1. Get this working with other versions of wine-staging - **Success**
1. Know what I'm doing - *Failed*

## Issues as I understand them

1. Issue [40528](https://bugs.winehq.org/show_bug.cgi?id=40528)
    - FAST_CWD - MSYS2 which uses the cygwin core pre 2.6.0 had a Windows XP
compatibility layer which functions normally in wine. However after 2.6.0, the
XP compatibility layer was removed. This means there is no way to have msys2
working with the most up to date msys2. So don't `pacman -Syyuu`
    - This problem first shows up in the 20160921 msys2 download

1. Issue [40483](https://bugs.winehq.org/show_bug.cgi?id=40483)
    - [Archived link](https://www.winehq.org/pipermail/wine-bugs/2016-July/447244.html)
    - This claims to be fixed in wine 1.9.24

1. Issue [40482](https://bugs.winehq.org/show_bug.cgi?id=40482)
    - "Support set title in start, needed by latest MSYS2"
    - Still not solved, basically don't use wineconsole to workaround. So we use mintty

1. Is MSYSTEM=MSYS important?
    - I don't know! Eventually it is used by the msys2 login scripts. It expects
mingw64 or mingw32, and shows up as part of the prompt. Changing this does not
appear to affect whether anything "works" or not

1. Scroll bars are nice
    - `wineconsole` and `wineconsole --backend ncurses` doesn't support this
    - [Abandoned](https://bugs.winehq.org/show_bug.cgi?id=5856)
    - mintty does

1. `pacman` upgrading msys2.
    - teaci has a good solution. Basically you have to point to their repos,
    which are still a little out of date, but a little more up to date

1. "workaround https://bugs.wine-staging.com/show_bug.cgi?id=403"
  - No idea. Lost to the void of internet time because wine thinks they are [smarter
than google](https://bugs.winehq.org/show_bug.cgi?id=35756).

1. "Work around https://bugs.wine-staging.com/show_bug.cgi?id=682"
    - No idea. Lost to the void of internet time because wine thinks they are [smarter
than google](https://bugs.winehq.org/show_bug.cgi?id=35756).
    - This affects whether mintty works or not
    - Here's what I do know. Ubuntu 14 has two versions of libfreetype6
      - [2.5.2-1ubuntu2](https://launchpad.net/ubuntu/trusty/amd64/libfreetype6/2.5.2-1ubuntu2) - Works
      - [2.5.2-1ubuntu2.8](https://launchpad.net/ubuntu/trusty/amd64/libfreetype6/2.5.2-1ubuntu2.8) - Doesn't work
      - 2.5.2-1ubuntu2 doesn't contain and of the updates after March 2014. So some CVE
  or backport patch after that breaks mintty
    - I don't think [this](https://bugs.winehq.org/show_bug.cgi?id=43715) is related
    - [Archive](https://www.winehq.org/pipermail/wine-bugs/2017-September/476182.html)

1. "Work around https://bugs.wine-staging.com/show_bug.cgi?id=626"
    - No idea. Lost to the void of internet time because wine thinks they are [smarter
than google](https://bugs.winehq.org/show_bug.cgi?id=35756).
    - winpty also recognizes a WINPTY_SHOW_CONSOLE environment variable. Set it to 1
to prevent winpty from hiding the console window.

1. You need a UTF-8 LC_ALL so that mintty displays

1. Black mintty
    - https://bugs.winehq.org/show_bug.cgi?id=44066
    - Versions of wine-staging after 2.4.0 result in mintty drawing
to X, but as a black screen. It is in fact working, you can type in it like
normally and it is working, you just can not see any thing. There will be a brief
glimpse at what should be seen when you click the X to close the screen. But
nothing else shows the graphics at all

1. What about wine 3?
    - I have not consistently tested wine 3.x, but any attempts have failed to run
in wine 3 graphically.

## Dev details

1. Why am I installing all the dependencies manually?
    - I got impatient. It just saves time when constantly rebuilding the docker
images. I'll remove that eventually

## The Experiments

- wine.Dockerfile - The main working version
- Dockerfile - The original "It works!" POC
- wine1.Dockerfile - Running in Fedora, which is my native OS. No luck at ALL
- wine2.Dockerfile - Closest reproductions of teaci/wine-staging with msys2
- wine3.Dockerfile - Basically, wine with all recommended packages too, just in
case
- wine4.Dockerfile - Using Ubuntu 16.04 - Works, but no mintty
- wine5.Dockerfile - Trying using Debian jessie. WORKS!
