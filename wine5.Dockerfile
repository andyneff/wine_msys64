FROM vsiri/recipe:gosu as gosu

FROM debian:8 as wine-staging
LABEL maintainer="Andy Neff <andrew.neff@visionsystemsinc.com>"

SHELL ["bash", "-euxvc"]

# This line just makes changing wine version faster
RUN dpkg --add-architecture i386; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    # staging-i386 depends
    libasound2:i386 libc6:i386 libexif12:i386 libgl1-mesa-glx:i386 libglib2.0-0:i386 libglu1-mesa:i386 libgphoto2-6:i386 libgphoto2-port10:i386 libgstreamer-plugins-base1.0-0:i386 libgstreamer1.0-0:i386 liblcms2-2:i386 libldap-2.4-2:i386 libmpg123-0:i386 libopenal1:i386 libpulse0:i386 libudev1:i386 libx11-6:i386 libxext6:i386 libxml2:i386 zlib1g:i386 libasound2-plugins:i386 libncurses5:i386 \
    # staging-amd64 depends
    libasound2 libc6 libexif12 libgcc1 libgl1-mesa-glx libglib2.0-0 libglu1-mesa libgphoto2-6 libgphoto2-port10 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 liblcms2-2 libldap-2.4-2 libmpg123-0 libopenal1 libpulse0 libudev1 libx11-6 libxext6 libxml2 zlib1g libasound2-plugins libncurses5 \
    # recommends that I need
    libfreetype6 libfreetype6; \
    apt-get clean -y

ARG WINEVERSION=2.4.0-3~jessie
RUN build_deps="curl ca-certificates"; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends ${build_deps}; \
    apt-key add <(curl -L https://dl.winehq.org/wine-builds/Release.key); \
    echo 'deb http://dl.winehq.org/wine-builds/debian/ jessie main' > /etc/apt/sources.list.d/wine.list; \
    dpkg --add-architecture i386; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
                    winehq-staging=${WINEVERSION} \
                    wine-staging=${WINEVERSION} \
                    wine-staging-i386=${WINEVERSION} \
                    wine-staging-amd64=${WINEVERSION}; \
    DEBIAN_FRONTEND=noninteractive apt-get purge --auto-remove -y ${build_deps}; \
    apt-get clean -y

# Without LC_ALL=en_US.UTF-8, you can not run:
#     wine 'C:\msys64\usr\bin\mintty' /usr/bin/bash
# However, you CAN still run:
#     wineconsole 'C:\msys64\usr\bin\mintty' /usr/bin/bash
# Not sure why. So might as well install UTF 8

# # RUN apt-get update; \
# #     DEBIAN_FRONTEND=noninteractive apt-get install -y locales; \
# #     apt-get clean -y; \
# #     echo en_US.UTF-8 UTF-8 > /etc/locale.gen; \
# #     locale-gen

# ENV LANG=en_US.UTF-8 \
#     LANGUAGE=en_US:en \
#     LC_ALL=en_US.UTF-8

####

# Font fun
RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                    # Latest mintty requires Lucida Console font
                    fonts-droid; \
    apt-get clean -y


FROM wine-staging as wine-init

#####################################
###### EXECUTION FREE ZONE!!!! ######
#####################################
# Normal "Clean" docker rules do not apply here,
# no reason to keep image minimal

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
                    xz-utils curl ca-certificates

ARG WINE_MONO_VERSION=4.7.1
ARG WINE_GECKO_VERSION=2.47

# The closest I could come to getting WINEPREFIX setup headless. I could use Xvfb
# if that was needed, but wine seems happy enough without it.
# wine-staging 2.10.0 permahangs on wineboot
RUN export WINEPREFIX=/home/wine; \
    mkdir -p /root/.cache/wine; \
    pushd /root/.cache/wine; \
      curl -LO http://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi; \
      curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86.msi; \
      curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86_64.msi; \
      wineboot; \
      wineserver -w; \
    popd
    # rm -r /root/.cache/wine

# This differentiation is only useful for a breaking point when someone wants to
# gut the wine part of this docker and not the msys64 part
FROM wine-init as msys64-init

### Setup msys64
ARG MSYS2_VERSION=20160205
RUN export WINEPREFIX=/home/wine; \
    cd /home/wine/drive_c; \
    curl -LO http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    tar xf msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    # rm msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \

    # Create reg file
    echo 'Windows Registry Editor Version 5.00' > /tmp/patch.reg; \
    # Patch the font for mintty - Make Lucida Console use Droid Sans Mono
    # https://www.codeweavers.com/support/forums/general?t=27;msg=191660
    echo '[HKEY_CURRENT_USER\Software\Wine\Fonts\Replacements]' >> /tmp/patch.reg; \
    echo '"Lucida Console"="Droid Sans Mono"' >> /tmp/patch.reg; \
    # Disable debug helper, instead of using winetricks noconsoledebug
    echo '[HKEY_CURRENT_USER\Software\Wine\WineDbg]' >> /tmp/patch.reg; \
    echo '"ShowCrashDialog"=dword:00000000' >> /tmp/patch.reg; \
    # Enable Windows XP mode
    echo '[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]' >> /tmp/patch.reg; \
    echo '"CSDVersion"="Service Pack 2"' >> /tmp/patch.reg; \
    echo '"CurrentBuildNumber"="3790"' >> /tmp/patch.reg; \
    echo '"CurrentVersion"="5.2"' >> /tmp/patch.reg; \
    echo '"ProductName"="Microsoft Windows XP"' >> /tmp/patch.reg; \
    echo '[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]' >> /tmp/patch.reg; \
    echo '"CSDVersion"=dword:00000200' >> /tmp/patch.reg; \
    # Enable Windows XP 32 mode just in case
    echo '[HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows NT\CurrentVersion]' >> /tmp/patch.reg; \
    echo '"CSDVersion"="Service Pack 2"' >> /tmp/patch.reg; \
    echo '"CurrentBuildNumber"="3790"' >> /tmp/patch.reg; \
    echo '"CurrentVersion"="5.2"' >> /tmp/patch.reg; \
    echo '"ProductName"="Microsoft Windows XP"' >> /tmp/patch.reg; \
    echo '[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]' >> /tmp/patch.reg; \
    echo '"CSDVersion"=dword:00000200' >> /tmp/patch.reg; \
    WINEDEBUG=fixme-all wine64 regedit /tmp/patch.reg; \
    wineserver -w
    # rm /tmp/patch.reg

FROM wine-staging

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

COPY --from=msys64-init /home/wine /home/wine

ENV TERM=xterm-256color \
    # Work around https://bugs.wine-staging.com/show_bug.cgi?id=626
    WINPTY_SHOW_CONSOLE=1 \
    MSYSTEM=mingw64

#### ENTRYPOINT IDEAS ####

# Initialize bash - Can't do this without privileged mode. Oh well
# RUN gosu user wine 'c:\msys64\usr\bin\bash.exe' -l :

# Create a temp bash so that updating works

RUN useradd -m -u 1033 user; \
    gosu user cp -ra /home/wine /home/user/.wine

#### END OF ENTRYPOINT IDEAS ####

# VOLUME /home/user/.wine

CMD cd /home/user/.wine/drive_c/msys64/; \
    gosu user bash
