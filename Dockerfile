FROM vsiri/recipe:gosu as gosu

FROM teaci/msys64

SHELL ["/bin/bash", "-euxvc"]

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

COPY wine_entrypoint_orig.bsh /

RUN chmod 755 /wine_entrypoint.bsh /root

# Disable those pesky fixme messages
ENV WINEDEBUG=fixme-all,err-menubuilder \
    WINEPREFIX=/root/.wine \
    USER_ID=1000

RUN useradd -m -u 1033 user; \
    cp -ra /root/.wine /home/user/; \
    chown -R user:user /home/user/.wine

ENV WINEPREFIX=/home/user/.wine_broke
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

ENTRYPOINT ["/wine_entrypoint.bsh"]

CMD []
