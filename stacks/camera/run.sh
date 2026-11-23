#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Missing .env - copy .env.example and fill it in" >&2; exit 1; }
LOG_OPTS=(--log-driver json-file --log-opt max-size=10m --log-opt max-file=3)

docker rm -f vivosun-fetcher go2rtc >/dev/null 2>&1 || true

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

docker run -d --name vivosun-fetcher \
  --restart unless-stopped \
  --network media \
  --env-file .env \
  -e TZ=Europe/Berlin \
  -e GO2RTC_API_URL=http://go2rtc:1984 \
  -e STREAM_NAME=rtsp-cam \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  "${LOG_OPTS[@]}" \
  ghcr.io/igridz/vivosun-fetcher:latest
