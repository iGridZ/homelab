#!/bin/sh
# Port-forwarding watchdog for gluetun (ProtonVPN NAT-PMP).
# Gluetun retries port forwarding on the same server forever. If no port is
# forwarded for MAX_FAILS checks in a row, reconnect the VPN through gluetun's
# control API. The reconnect happens inside gluetun, so qBittorrent and mousehole
# keep their network. The new port reaches qBittorrent via the up command.
set -u

API=http://127.0.0.1:8000
KEY="${GLUETUN_API_KEY:?set GLUETUN_API_KEY}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"   # seconds between checks
MAX_FAILS="${MAX_FAILS:-3}"              # 3 x 60 s = reconnect after ~3 min without a port
GRACE="${GRACE:-180}"                    # wait after start / reconnect before checking

log() { echo "$(date '+%F %T') $*"; }
api() { wget -qO- -T 10 --header="X-API-Key: $KEY" "$@"; }
vpn() {
  api --method=PUT --header='Content-Type: application/json' \
    --body-data="{\"status\":\"$1\"}" "$API/v1/vpn/status" >/dev/null
}
forwarded_port() {
  api "$API/v1/portforward" | sed -n 's/.*"port":\([0-9]*\).*/\1/p'
}

log "started: check every ${CHECK_INTERVAL}s, reconnect after ${MAX_FAILS} misses"
sleep "$GRACE"
fails=0
while true; do
  port="$(forwarded_port)"
  if [ "${port:-0}" -gt 0 ] 2>/dev/null; then
    [ "$fails" -gt 0 ] && log "port $port forwarded again"
    fails=0
  else
    fails=$((fails + 1))
    log "no forwarded port ($fails/$MAX_FAILS)"
  fi
  if [ "$fails" -ge "$MAX_FAILS" ]; then
    log "reconnecting VPN"
    vpn stopped || log "stop request failed"
    sleep 5
    vpn running || log "start request failed"
    fails=0
    sleep "$GRACE"
    continue
  fi
  sleep "$CHECK_INTERVAL"
done
