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
        unzip \
        xvfb \
        xauth \
        gosu \
        jq \
        tzdata \
        procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG DEPOT_DOWNLOADER_VERSION=3.4.0
RUN curl -sL \
    "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" \
    -o /tmp/dd.zip && \
    unzip /tmp/dd.zip -d /depotdownloader && \
    chmod +x /depotdownloader/DepotDownloader && \
    rm /tmp/dd.zip

RUN useradd -m -s /bin/bash steam

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
