#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

COMMON=(--restart unless-stopped --network media --security-opt no-new-privileges:true
        --log-driver json-file --log-opt max-size=10m --log-opt max-file=3
        -e TZ=Europe/Berlin -e PUID=1000 -e PGID=1000)

docker rm -f sonarr radarr sabnzbd >/dev/null 2>&1 || true

docker run -d --name sonarr "${COMMON[@]}" -e UMASK=002 \
  -v /docker/configs/sonarr:/config \
  -v /media/share:/data \
  -v /home/rock/downloads:/downloads \
  ghcr.io/hotio/sonarr:release-4.0.20.3014

docker run -d --name radarr "${COMMON[@]}" -e UMASK=002 \
  -v /docker/configs/radarr:/config \
  -v /media/share:/data \
  -v /home/rock/downloads:/downloads \
  ghcr.io/hotio/radarr:release-6.4.4.10685

docker run -d --name sabnzbd "${COMMON[@]}" \
  -v /docker/configs/sabnzbd:/config \
  -v /home/rock/downloads:/downloads \
  -v /home/rock/incomplete/downloads:/incomplete-downloads \
  -v /media/share/download:/software \
  lscr.io/linuxserver/sabnzbd:5.1.3
