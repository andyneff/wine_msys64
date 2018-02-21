Getting msys2 to work in wine is very tricky. Here is a set of docker images
based off of https://github.com/TeaCI/msys2-docker that should work with Linux
base images other than Ubuntu 14.04.

## TL;DR

```bash
docker run -it --rm --cap-add SYS_PTRACE \
           -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
           -v wine_ubuntu_14.04:/home/.user_wine \
           -e DISPLAY -e USER_ID=`id -u` \
           andyneff/wine_msys64:ubuntu_14.04

#or

docker-compose run -e USER_ID=`id -u` --rm ubuntu_14.04
```

## Running with bells and whistles

```
. setup.env # Only need to run this once
just run ubuntu_14.04
```

## Graphics

With these dockers you can run MSYS2 bash in a docker either graphically
(which leverages `mintty.exe`) or non-grapically using wineconsole in ncurses
mode. All of the bugs I have encountered have been worked around to the best
of my ability and should work out of the box.

## Special command

1. `root` - Starts the container as root in normal bash. From there, you can do
   What is needed as root. To run wine commands

    ```
    gosu user wineconsole # etc...
    ```

## Options

1. `DISPLAY` - Environment variable
    - By default, copies your current `DISPLAY` host value. You can set it to
      something else, or set it to null (blank) to disable graphics
1. `USER_ID` - Environment variable
    - Sets the UID inside the docker to match the user_id on the host. This
      makes X11 work smoother, and files that you write to other mounted volumes
      be owned correctly
1. `GROUP_ID` - Environment variable
    - Set the GID inside the docker, less important, but nice to have it match
1. `FAST_WINE_DIR`  - Environment variable
    - "You do a lot of ownership stuff for files, and it takes time, and I really
      don't care about it, can you stop that?"
    - Sure! Just set the environment variable `FAST_WINE_DIR` to anything
1. `WINE_MONO_VERSION`, `WINE_GECKO_VERSION`, `WINE_VERSION`, `MSYS2_VERSION` - Build Argument
    - Build args you can change to easily change these versions. But be careful
      MSYS2 may not work with the wine version you pick
    - The repo that docker image is configured with might not have the wine
      version you want too.
1. `MSYSTEM` - Environment variable
    - Can be set to MINGW64, MINGW32, or MSYS2 for the desired mode.
    - Defaults to MINGW64
1. `MSYS2_WINE_WORKAROUND` - Environment variable
    - 0 for debian:8 based OSes, 1 for all others. If additional workarounds
      are needed, then 2, 3, 4, etc...
1. `CHERE_INVOKING` Environment variable
    - By default, a login shell on msys2 will change to the home directory. This
      behavior is disabled by default, to re-enable it, set `CHERE_INVOKING` to
      a blank string

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
