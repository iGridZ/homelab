#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Missing .env - copy .env.example and fill it in" >&2; exit 1; }
LOG_OPTS=(--log-driver json-file --log-opt max-size=10m --log-opt max-file=3)

docker rm -f vivosun-fetcher frigate go2rtc >/dev/null 2>&1 || true

docker run -d --name go2rtc \
  --restart unless-stopped \
  --network media \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -e TZ=Europe/Berlin \
  -p 8555:8555/tcp \
  -v /docker/config/go2rtc:/config \
  "${LOG_OPTS[@]}" \
  alexxit/go2rtc:1.9.15

docker run -d --name frigate \
  --restart unless-stopped \
  --network media \
  --shm-size 256m \
  --device /dev/bus/usb:/dev/bus/usb \
  --device /dev/dri/renderD128:/dev/dri/renderD128 \
  --security-opt no-new-privileges:true \
  -v /docker/config/frigate:/config \
  -v /home/rock/media:/media/frigate \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp/cache \
  "${LOG_OPTS[@]}" \
  ghcr.io/blakeblackshear/frigate:0.18.2

docker run -d --name vivosun-fetcher \
  --restart unless-stopped \
  --network media \
  --env-file .env \
  -e TZ=Europe/Berlin \
  -e GO2RTC_API_URL=http://go2rtc:1984,http://frigate:1984 \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  "${LOG_OPTS[@]}" \
  ghcr.io/igridz/vivosun-fetcher:latest
