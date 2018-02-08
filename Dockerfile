FROM vsiri/recipe:gosu as gosu

FROM teaci/msys64

SHELL ["/bin/bash", "-euxvc"]

COPY --from=gosu /usr/local/bin/gosu /usr/bin/gosu

COPY wine_entrypoint.bsh /

RUN chmod 755 /wine_entrypoint.bsh /root

# Disable those pesky fixme messages
ENV WINEDEBUG=fixme-all \
    WINEPREFIX=/root/.wine \
    USER_ID=1000

ENTRYPOINT ["/wine_entrypoint.bsh"]

CMD []
