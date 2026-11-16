#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

docker rm -f portainer >/dev/null 2>&1 || true
docker run -d --name portainer \
  --restart unless-stopped \
  -e TZ=Europe/Berlin \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  --security-opt no-new-privileges:true \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  portainer/portainer-ee:2.45.3
