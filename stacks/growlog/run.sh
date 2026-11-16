#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

docker rm -f growlog >/dev/null 2>&1 || true
docker run -d --name growlog \
  --restart unless-stopped \
  --network media \
  -e TZ=Europe/Berlin \
  -v /docker/data/growlog:/data \
  --read-only --tmpfs /tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  ghcr.io/igridz/growlog:latest
