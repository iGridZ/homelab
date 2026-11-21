#!/usr/bin/env bash
# Same configuration as compose.yaml, as plain docker CLI commands.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Missing .env - copy .env.example and fill it in" >&2; exit 1; }
set -a; . ./.env; set +a
: "${PROTON_WG_PRIVATE_KEY:?set PROTON_WG_PRIVATE_KEY in .env}"
: "${MOUSEHOLE_AUTH_PASSWORD:?set MOUSEHOLE_AUTH_PASSWORD in .env}"

LOG_OPTS=(--log-driver json-file --log-opt max-size=10m --log-opt max-file=3)

read -r -d '' UP_CMD <<'CMD' || true
/bin/sh -c 'wget -O- -nv --retry-connrefused --post-data "json={\"listen_port\":{{PORT}},\"current_network_interface\":\"{{VPN_INTERFACE}}\",\"random_port\":false,\"upnp\":false}" http://127.0.0.1:8085/api/v2/app/setPreferences'
CMD
read -r -d '' DOWN_CMD <<'CMD' || true
/bin/sh -c 'wget -O- -nv --retry-connrefused --post-data "json={\"listen_port\":0,\"current_network_interface\":\"lo\"}" http://127.0.0.1:8085/api/v2/app/setPreferences'
CMD

docker rm -f mousehole qbittorrent gluetun >/dev/null 2>&1 || true
docker volume create mousehole >/dev/null

docker run -d --name gluetun \
  --restart unless-stopped \
  --cap-add NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -e TZ=Europe/Berlin \
  -e VPN_SERVICE_PROVIDER=protonvpn \
  -e VPN_TYPE=wireguard \
  -e WIREGUARD_PRIVATE_KEY="$PROTON_WG_PRIVATE_KEY" \
  -e SERVER_COUNTRIES="${PROTON_SERVER_COUNTRIES:-Netherlands}" \
  -e PORT_FORWARD_ONLY=on \
  -e VPN_PORT_FORWARDING=on \
  -e VPN_PORT_FORWARDING_UP_COMMAND="$UP_CMD" \
  -e VPN_PORT_FORWARDING_DOWN_COMMAND="$DOWN_CMD" \
  -p 8085:8085 \
  -p 5010:5010 \
  -v /docker/configs/gluetun:/gluetun \
  "${LOG_OPTS[@]}" \
  qmcgaw/gluetun:v3.41.3

echo "Waiting for gluetun to become healthy..."
until [ "$(docker inspect -f '{{.State.Health.Status}}' gluetun)" = "healthy" ]; do sleep 3; done

docker run -d --name qbittorrent \
  --restart unless-stopped \
  --network container:gluetun \
  -e TZ=Europe/Berlin -e PUID=1000 -e PGID=1000 -e WEBUI_PORT=8085 \
  -v /docker/configs/qbittorrent:/config \
  -v /media/share/mam:/data/mam \
  --security-opt no-new-privileges:true \
  "${LOG_OPTS[@]}" \
  lscr.io/linuxserver/qbittorrent:5.2.3-libtorrentv1

docker run -d --name mousehole \
  --restart unless-stopped \
  --network container:gluetun \
  -e TZ=Europe/Berlin \
  -e MOUSEHOLE_AUTH_PASSWORD="$MOUSEHOLE_AUTH_PASSWORD" \
  -v mousehole:/var/lib/mousehole \
  --security-opt no-new-privileges:true \
  "${LOG_OPTS[@]}" \
  tmmrtn/mousehole:0.5.0
