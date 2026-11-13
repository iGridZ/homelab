#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

IMAGE="willfarrell/autoheal:latest@sha256:53320121f32db551b8e19cdd5ff28eb1e5cece62845cc46683d4479b6a58b77e"

docker rm -f autoheal >/dev/null 2>&1 || true
docker run -d --name autoheal \
  --restart unless-stopped \
  --network none \
  -e TZ=Europe/Berlin \
  -e AUTOHEAL_CONTAINER_LABEL=all \
  -e AUTOHEAL_INTERVAL=5 \
  -e AUTOHEAL_DEFAULT_STOP_TIMEOUT=10 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/localtime:/etc/localtime:ro \
  --security-opt no-new-privileges:true \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  "$IMAGE"
