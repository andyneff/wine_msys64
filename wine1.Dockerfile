# Doesn't work AT ALL :( not even bash

FROM vsiri/recipe:gosu as gosu

FROM fedora:27
## FROM teaci/wine-staging

SHELL ["bash", "-euxvc"]

# Version 2.0 to 3.1 don't work, stupid FAST_CWD bug :(
ARG WINE_VERSION=staging-1:2.4-3
RUN dnf install -y 'dnf-command(config-manager)'; \
    dnf config-manager --add-repo https://repos.wine-staging.com/wine/fedora/24/winehq.repo; \
    #curl -L https://dl.winehq.org/wine-builds.old/fedora/23/winehq.repo | sed 's|wine-builds|wine-builds.old|' > /dev/shm/winehq.repo; \
    # dnf config-manager --add-repo /dev/shm/winehq.repo; \
    dnf remove -y 'dnf-command(config-manager)'; \
    dnf install -y winehq-${WINE_VERSION}.x86_64; \
# RUN dnf install -y wine winetricks; \
    dnf clean all

RUN curl -L -o /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/20171222/src/winetricks; \
    chmod 755 /usr/local/bin/winetricks

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

RUN useradd user -m -u 1033

# The closest I could come to getting WINEPREFIX setup headless
ARG WINE_MONO_VERSION=4.7.1
ARG WINE_GECKO_VERSION=2.47
RUN gosu user mkdir -p /home/user/.cache/wine; \
    cd /home/user/.cache/wine; \
    gosu user curl -LO http://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi; \
    gosu user curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86.msi; \
    gosu user curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86_64.msi; \
    gosu user wineboot; \
    gosu user wineserver -w; \
    rm -r /home/user/.cache/wine

ARG MSYS2_VERSION=20160205
RUN cd /home/user/.wine/drive_c; \
    dnf install -y xz; \
    gosu user curl -LO http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    gosu user tar xf msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    rm msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    dnf remove -y xz; \
    dnf clean all

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    MSYSTEM=mingw64

# RUN echo 'REGEDIT4' > /tmp/lucida.reg; \
#     echo '[HKEY_CURRENT_USER\Software\Wine\Fonts\Replacements]' >> /tmp/lucida.reg; \
#     echo '"Lucida Console"="Droid Sans Mono"' >> /tmp/lucida.reg; \
#     WINEDEBUG=fixme-all regedit /tmp/lucida.reg; \
#     wineserver -w; \
#     rm /tmp/lucida.reg

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

# RUN gosu user mkdir /home/user/.wine/drive_c/works; \
#     cd /home/user/.wine/drive_c/works; \
#     #gosu user wget -q http://mirrors.tea-ci.org/msys2/distrib/msys2-x86_64-latest.tar.xz
#     gosu user wget -q http://mirrors.tea-ci.org/msys2/distrib/x86_64/msys2-base-x86_64-20160205.tar.xz; \
#     tar xf msys2-base-x86_64-20160205.tar.xz; \
#     rm msys2-base-x86_64-20160205.tar.xz

#### ENTRYPOINT IDEAS ####

# Initialize bash - Can't do this without privileged mode. Oh well
# RUN gosu user wine 'c:\msys64\usr\bin\bash.exe' -l :

# Create a temp bash so that updating works
RUN gosu user cp /home/user/.wine/drive_c/msys64/usr/bin/bash.exe \
                 # /home/user/.wine/drive_c/msys64/usr/bin/msys-2.0.dll \
                 /home/user/.wine/drive_c/msys64/var/tmp

#### END OF ENTRYPOINT IDEAS ####

VOLUME /home/user/.wine

CMD cd /home/user/.wine/drive_c/msys64/; \
    gosu user bash