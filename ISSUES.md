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
    - Versions of wine-staging after 2.4.0 result in `mintty.exe` drawing
to X, but as a black screen. It is in fact working, you can type in it like
normally and it is working, you just can not see any thing. There will be a brief
glimpse at what should be seen when you click the X to close the screen. But
nothing else shows the graphics at all
    - `mingw64.exe` behaves the same way.
    - `bash` in `wineconsole` does work mostly, but you will have no scrollbars

1. UTF-8
    - Without LC_ALL=en_US.UTF-8 and the locale setup, mintty didn't work right
on Ubuntu 14.04, so I just keep doing that for all OSes
    - Without LC_ALL=en_US.UTF-8, you can not run:

        wine 'C:\msys64\usr\bin\mintty' /usr/bin/bash

    - However, you CAN still run:

        wineconsole 'C:\msys64\usr\bin\mintty' /usr/bin/bash

    - Not sure why. So might as well install UTF 8

1. What about wine 3?
    - I have not consistently tested wine 3.x, but any attempts have failed to run
in wine 3 graphically.

1. On anything not debian 8 based

    ```
    *Works*
    usr\bin\mintty /usr/bin/bash -l > nul
    usr\bin\mintty "/usr/bin/bash" -l
    usr\bin\mintty "/usr/bin/bash
    mingw64.exe

    *Doesn't work*
    usr\bin\mintty
    echo hi | usr\bin\mintty
    usr\bin\mintty /usr/bin/bash # althought this works on ubuntu 14
    usr\bin\mintty //usr/bin/bash
    usr\bin\mintty ////usr/bin/bash
    ```

    `MSYS2_WINE_WORKAROUND` selects to use a workaround to this, which results in
    a extract wineconsole window hanging around

1. Why am I installing all the dependencies manually?
    - I got impatient. It just saves time when constantly rebuilding the docker
      images. I'll remove that eventually
