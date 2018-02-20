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

## Options

1. `USER_ID`
    - Sets the USER_ID inside the docker to match the user_id on the host. This
      makes X11 work smoother, and files that you write to other mounted volumes
      be owned correctly
1. `FAST_WINE_DIR`
    - "You do a lot of ownership stuff for files, and it takes time, and I really
      don't care about it, can you stop that?"
    - Sure! Just set the environment variable `FAST_WINE_DIR` to anything
1. `WINE_MONO_VERSION`, `WINE_GECKO_VERSION`, `WINE_VERSION`
    - Build args you can change to easily change these versions. But be careful
      MSYS2 may not work with the wine version you pick
    - The repo that docker image is configured with might not have the wine
      version you want too.
1. `MSYS2_WINE_WORKAROUND`
    - 0 for debian:8 based OSes, 1 for all others. If additional workarounds
      are needed, then 2, 3, 4, etc...

## Motivation

- The [original repo](https://github.com/TeaCI/msys2-docker) is sort of out
of date and cannot be reproduced using just the git repo. And only works on
Ubuntu 14 in a very special configuration. While little progress has been
made into solving the main cygwin core v2.6 in wine, I wanted to reproduce
this work, and update where possible.

- Even the links to the bugs that the TeaCI docker fixes no longer work. Thanks
winehq!

- There was a lack of documentation. Like knowing you need to run `--privileged`,
and actually knowing you just need to run `--cap-add=SYS_PTRACE` and the way they
had it set up, `xhost +`, etc... There was no readme to help with that
