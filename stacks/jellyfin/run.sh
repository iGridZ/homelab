#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

mkdir -p /docker/configs/jellyfin-cache
docker rm -f jellyfin >/dev/null 2>&1 || true
docker run -d --name jellyfin \
  --restart unless-stopped \
  --network media \
  -p 8096:8096 \
  -e TZ=Europe/Berlin \
  --device /dev/dri/renderD128:/dev/dri/renderD128 \
  -v /docker/configs/jellyfin:/config \
  -v /docker/configs/jellyfin-cache:/cache \
  -v /media/share/sonarr:/tv \
  -v /media/share/radarr:/movies \
  --security-opt no-new-privileges:true \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  jellyfin/jellyfin:12.4.20261026-211555
