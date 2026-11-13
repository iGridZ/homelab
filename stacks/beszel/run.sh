#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail
cd "$(dirname "$0")"

VERSION=0.21.1
[ -f .env ] || { echo "Missing .env - copy .env.example and fill it in" >&2; exit 1; }
set -a; . ./.env; set +a
: "${BESZEL_AGENT_KEY:?set BESZEL_AGENT_KEY in .env}"
: "${BESZEL_AGENT_TOKEN:?set BESZEL_AGENT_TOKEN in .env}"

LOG_OPTS=(--log-driver json-file --log-opt max-size=10m --log-opt max-file=3)

docker rm -f beszel beszel-agent >/dev/null 2>&1 || true

docker run -d --name beszel \
  --restart unless-stopped \
  --network media \
  -p 8090:8090 \
  -e TZ=Europe/Berlin \
  -e APP_URL=http://localhost:8090 \
  -v beszel_data:/beszel_data \
  --security-opt no-new-privileges:true \
  --health-cmd "/beszel health --url http://localhost:8090" \
  --health-interval 120s --health-start-period 10s \
  "${LOG_OPTS[@]}" \
  "henrygd/beszel:${VERSION}"

docker run -d --name beszel-agent \
  --restart unless-stopped \
  --network host \
  -e TZ=Europe/Berlin \
  -e LISTEN=45876 \
  -e HUB_URL=http://localhost:8090 \
  -e KEY="$BESZEL_AGENT_KEY" \
  -e TOKEN="$BESZEL_AGENT_TOKEN" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v beszel_agent_data:/var/lib/beszel-agent \
  --security-opt no-new-privileges:true \
  --health-cmd "/agent health" \
  --health-interval 120s --health-start-period 10s \
  "${LOG_OPTS[@]}" \
  "henrygd/beszel-agent:${VERSION}"

echo "Beszel running: http://$(hostname -I | awk '{print $1}'):8090"
