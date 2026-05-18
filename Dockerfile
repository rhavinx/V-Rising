FROM debian:trixie-slim

LABEL org.opencontainers.image.authors="rhavinx"
LABEL org.opencontainers.image.source="https://github.com/rhavinx/vrising"
LABEL org.opencontainers.image.description="V Rising Dedicated Server"

ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wine \
        wine32 \
        wine64 \
        winbind \
        curl \
        lib32gcc-s1 \
        xvfb \
        xauth \
        gosu \
        jq \
        tzdata \
        procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steam

# Bootstrap steamcmd — creates ~/.steam/sdk64/steamclient.so which Wine needs for Steamworks GameServer calls
RUN mkdir -p /home/steam/steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | \
        tar zxf - -C /home/steam/steamcmd && \
    chown -R steam:steam /home/steam/steamcmd && \
    su - steam -c "/home/steam/steamcmd/steamcmd.sh +quit"

ENV SERVERHOME="/home/steam/vrising/server"
ENV GAMEDATA="/home/steam/vrising/data"

COPY start.sh /start.sh

RUN mkdir -p ${SERVERHOME} ${GAMEDATA} && \
    chmod +x /start.sh && \
    chown -R steam:steam /home/steam/vrising

VOLUME ["/home/steam/vrising/server", "/home/steam/vrising/data"]

EXPOSE 9876/udp
EXPOSE 9877/udp

ENTRYPOINT ["/start.sh"]
