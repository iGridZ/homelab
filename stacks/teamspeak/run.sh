#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail

docker rm -f teamspeak-server >/dev/null 2>&1 || true
docker run -d --name teamspeak-server \
  --restart unless-stopped \
  -e TZ=Europe/Berlin \
  -e TSSERVER_LICENSE_ACCEPTED=accept \
  -p 42069:9987/udp \
  -p 30033:30033/tcp \
  -v teamspeak-data:/var/tsserver \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  teamspeaksystems/teamspeak6-server:6.0.0-beta13.1
