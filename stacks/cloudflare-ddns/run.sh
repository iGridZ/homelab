#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail
cd "$(dirname "$0")"

VERSION=1.17.1
[ -f .env ] || { echo "Missing .env - copy .env.example and fill it in" >&2; exit 1; }
set -a; . ./.env; set +a
: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN in .env}"
: "${DOMAINS:?set DOMAINS in .env}"

docker rm -f cloudflare-ddns >/dev/null 2>&1 || true
docker run -d --name cloudflare-ddns \
  --restart unless-stopped \
  --network host \
  --user 1000:1000 \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -e TZ=Europe/Berlin \
  -e CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
  -e DOMAINS="$DOMAINS" \
  -e PROXIED=false \
  -e IP6_PROVIDER=none \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  "favonia/cloudflare-ddns:${VERSION}"
