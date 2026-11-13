#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
# Usage: ./run.sh            changedetection only
#        ./run.sh --browser  plus the headless Chrome
set -euo pipefail

NET=changedetection_default
LOG_OPTS=(--log-driver json-file --log-opt max-size=10m --log-opt max-file=3)

docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET" >/dev/null
docker rm -f changedetection playwright-chrome >/dev/null 2>&1 || true

docker run -d --name changedetection \
  --restart unless-stopped \
  --network "$NET" \
  -p 5001:5000 \
  -e TZ=Europe/Berlin \
  -e PLAYWRIGHT_DRIVER_URL=ws://playwright-chrome:3000 \
  -v /docker/changedetection:/datastore \
  --security-opt no-new-privileges:true \
  --health-cmd "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000', timeout=5)\"" \
  --health-interval 60s --health-timeout 10s --health-start-period 30s \
  "${LOG_OPTS[@]}" \
  dgtlmoon/changedetection.io:0.60.10

if [ "${1:-}" = "--browser" ]; then
  docker run -d --name playwright-chrome \
    --restart unless-stopped \
    --network "$NET" \
    -e TZ=Europe/Berlin \
    -e SCREEN_WIDTH=1920 -e SCREEN_HEIGHT=1024 -e SCREEN_DEPTH=16 \
    -e MAX_CONCURRENT_CHROME_PROCESSES=4 \
    -e LOG_LEVEL=INFO \
    --memory 1g \
    --security-opt no-new-privileges:true \
    "${LOG_OPTS[@]}" \
    dgtlmoon/sockpuppetbrowser:0.0.4
fi
