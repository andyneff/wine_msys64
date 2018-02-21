FROM vsiri/recipe:gosu as gosu

FROM centos:7 as wine-staging

SHELL ["bash", "-euxvc"]













# Available in epel-release libbsd ocl-icd

# This package would cause dependencies to be installed from fedora, when
# eveything is actually available from centos. Preinstall them
RUN yum install -y iproute\
    # These packages would try to install from fedora-updates, when I have them
    # centos already. Preinstall them
    cups-libs dbus-libs flac-libs flac-libs.i686 hicolor-icon-theme hwdata \
    liberation-fonts-common liberation-mono-fonts liberation-narrow-fonts liberation-sans-fonts liberation-serif-fonts \
    libgphoto2 libgphoto2.i686 libjpeg-turbo libjpeg-turbo.i686 libtool-ltdl libtool-ltdl.i686 \
    libvorbis libvorbis.i686 libwbclient mesa-libGLU mesa-libGLU.i686 \
    perl-Encode perl-Filter perl-Pod-Usage perl-threads perl-threads-shared \
    samba-common samba-libs samba-winbind samba-winbind-clients samba-winbind-modules \
    sqlite \
    # These packages would cause other packages to update from fedora-update
    nss-softokn pulseaudio-libs.i686; \
    yum clean all

ADD fedora.repo /etc/yum.repos.d/

# Fedora 19 https://getfedora.org/static/FB4B18E6.txt; \
# Fedora 20 https://getfedora.org/static/246110C1.txt
# Fedora 21 https://getfedora.org/static/95A43F54.txt
# Fedora 22 https://getfedora.org/static/8E1431D5.txt
RUN sed -i 's|19|22|g' /etc/yum.repos.d/fedora.repo; \
    curl -Lo /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-x86_64 https://getfedora.org/static/8E1431D5.txt; \
    # These typically can only be foudn 64 bit in centos or epel
    yum install -y avahi libdaemon; \
    yum install --enablerepo=fedora -y \
                nss-mdns nss-mdns.i686 \
                openal-soft openal-soft.i686\
                ocl-icd ocl-icd.i686 \
                libgphoto2.i686 libgphoto2 \
                libva.i686 libva; \
    yum clean --enablerepo=fedora all

# # This can be found in epel release
# RUN yum install -y epel-release; \
#     yum install -y libbsd; \
#     yum clean all

    # The actual install command
RUN yum install --enablerepo=fedora-updates --exclude=dbus -y wine; \
    # Go fedora or go home
    # yum install --enablerepo=fedora --enablerepo=fedora-updates -y wine; \
    yum clean --enablerepo=fedora-updates all


# ARG WINE_VERSION=staging-1:2.4-3
# RUN sed 's|wine-builds|wine-builds.old|' \
#         <(curl -Ls https://dl.winehq.org/wine-builds.old/fedora/23/winehq.repo) >\
#         /etc/yum.repos.d/winehq.repo; \
#     yum install -y winehq-${WINE_VERSION}.x86_64; \
#     yum clean all
























# Font fun
RUN yum install -y epel-release; \
    yum install -y google-droid-sans-mono-fonts; \
    yum clean all







FROM wine-staging as wine-init

# Normal "Clean" docker rules do not apply here, no reason to keep image minimal
RUN yum install -y xz; \
    yum clean all




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
    MSYS2_WINE_WORKAROUND=1

ADD wine_entrypoint.bsh /
RUN chmod 755 /wine_entrypoint.bsh
ENTRYPOINT ["/wine_entrypoint.bsh"]

CMD []