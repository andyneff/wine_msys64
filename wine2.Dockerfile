FROM vsiri/recipe:gosu as gosu

### Teaci/wine-staging

FROM ubuntu:14.04
LABEL maintainer="Andy Neff <andrew.neff@visionsystemsinc.com>"

SHELL ["bash", "-euxvc"]

RUN dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y software-properties-common; \
    add-apt-repository -y ppa:wine/wine-builds; \
    apt-get update; \
    apt-get install -y --install-recommends \
      wine-staging winehq-staging winetricks wget xvfb winbind fonts-droid; \
    apt-get clean -y

RUN apt-get update; \
    apt-get install -y language-pack-en-base language-pack-en; \
    apt-get clean -y; \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    MSYSTEM=mingw64

####

# Work around https://bugs.wine-staging.com/show_bug.cgi?id=682
RUN wget -q http://security.ubuntu.com/ubuntu/pool/main/f/freetype/libfreetype6_2.5.2-1ubuntu2_i386.deb; \
    wget -q http://security.ubuntu.com/ubuntu/pool/main/f/freetype/libfreetype6_2.5.2-1ubuntu2_amd64.deb; \
    dpkg -i libfreetype6_2.5.2-1ubuntu2_amd64.deb libfreetype6_2.5.2-1ubuntu2_i386.deb
# Work around https://bugs.wine-staging.com/show_bug.cgi?id=626
ENV WINPTY_SHOW_CONSOLE 1

####

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

RUN useradd user -m -u 1033

# The closest I could come to getting WINEPREFIX setup headless
# ARG WINE_MONO_VERSION=4.6.2
# ARG WINE_GECKO_VERSION=2.47-beta1
ARG WINE_MONO_VERSION=4.7.1
ARG WINE_GECKO_VERSION=2.47
RUN gosu user mkdir -p /home/user/.cache/wine; \
    cd /home/user/.cache/wine; \
    gosu user wget -q http://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi; \
    gosu user wget -q http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86.msi; \
    gosu user wget -q http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86_64.msi; \
    gosu user wineboot; \
    gosu user wineserver -w; \
    rm -r /home/user/.cache/wine


ARG MSYS2_VERSION=20160205
RUN cd /home/user/.wine/drive_c; \
    gosu user wget -q http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    gosu user tar xf msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    rm msys2-base-x86_64-${MSYS2_VERSION}.tar.xz

RUN echo 'Windows Registry Editor Version 5.00' > /tmp/patch.reg; \
    echo '[HKEY_CURRENT_USER\Software\Wine\Fonts\Replacements]' >> /tmp/patch.reg; \
    echo '"Lucida Console"="Droid Sans Mono"' >> /tmp/patch.reg; \
    echo '[HKEY_CURRENT_USER\Software\Wine\WineDbg]' >> /tmp/patch.reg; \
    echo '"ShowCrashDialog"=dword:00000000' >> /tmp/patch.reg; \
    echo '[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]' >> /tmp/patch.reg; \
    echo '"CSDVersion"="Service Pack 2"' >> /tmp/patch.reg; \
    echo '"CurrentBuildNumber"="3790"' >> /tmp/patch.reg; \
    echo '"CurrentVersion"="5.2"' >> /tmp/patch.reg; \
    echo '"ProductName"="Microsoft Windows XP"' >> /tmp/patch.reg; \
    echo '[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]' >> /tmp/patch.reg; \
    echo '"CSDVersion"=dword:00000200' >> /tmp/patch.reg; \
    WINEDEBUG=fixme-all gosu user wine regedit /tmp/patch.reg; \
    WINEDEBUG=fixme-all gosu user wine64 regedit /tmp/patch.reg; \
    gosu user wineserver -w; \
    rm /tmp/patch.reg

#### ENTRYPOINT IDEAS ####

# Initialize bash - Can't do this without privileged mode. Oh well
# RUN gosu user wine 'c:\msys64\usr\bin\bash.exe' -l :

# Create a temp bash so that updating works
RUN gosu user cp /home/user/.wine/drive_c/msys64/usr/bin/bash.exe \
                 # /home/user/.wine/drive_c/msys64/usr/bin/msys-2.0.dll \
                 /home/user/.wine/drive_c/msys64/var/tmp

#### END OF ENTRYPOINT IDEAS ####

# VOLUME /home/user/.wine

CMD cd /home/user/.wine/drive_c/msys64/; \
    gosu user bash