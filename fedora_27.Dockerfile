FROM vsiri/recipe:gosu as gosu

FROM fedora:27 as wine-staging

SHELL ["bash", "-euxvc"]





















ARG WINE_VERSION=staging-1:2.4-3
RUN dnf install -y 'dnf-command(config-manager)'; \
    dnf config-manager --add-repo https://repos.wine-staging.com/wine/fedora/24/winehq.repo; \
    dnf remove -y 'dnf-command(config-manager)'; \
    dnf install -y winehq-${WINE_VERSION}.x86_64; \
    dnf clean all
























# Font fun
RUN dnf install -y google-droid-sans-mono-fonts; \
    dnf clean all



















FROM wine-staging as wine-init

# Normal "Clean" docker rules do not apply here, no reason to keep image minimal
RUN dnf install -y xz; \
    dnf clean all




ARG WINE_MONO_VERSION=4.7.1
ARG WINE_GECKO_VERSION=2.47

# The closest I could come to getting WINEPREFIX setup headless. I could use Xvfb
# if that was needed, but wine seems happy enough without it.
RUN export WINEPREFIX=/home/wine; \
    mkdir -p /root/.cache/wine; \
    pushd /root/.cache/wine; \
      curl -LO http://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi; \
      curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86.msi; \
      curl -LO http://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine_gecko-${WINE_GECKO_VERSION}-x86_64.msi; \
      wineboot; \
      wineserver -w; \
    popd

# This differentiation is only useful for a breaking point when someone wants to
# gut the wine part of this docker and not the msys64 part
FROM wine-init as msys64-init

### Setup msys64
ARG MSYS2_VERSION=20160719
RUN export WINEPREFIX=/home/wine; \
    cd /home/wine/drive_c; \
    curl -L -o /tmp/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz \
         http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \
    tar xf /tmp/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz; \

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

FROM wine-staging
LABEL maintainer="Andy Neff <andrew.neff@visionsystemsinc.com>"

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

COPY --from=msys64-init /home/wine /home/wine

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    WINPTY_SHOW_CONSOLE=1 \
    MSYSTEM=MINGW64 \
    MSYS2_WINE_WORKAROUND=1 \
    CHERE_INVOKING=1

ADD wine_entrypoint.bsh /
RUN chmod 755 /wine_entrypoint.bsh
ENTRYPOINT ["/wine_entrypoint.bsh"]

CMD []