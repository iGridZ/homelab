# 0002 – FRITZ!Box WireGuard instead of a containerized VPN

- **Status:** Accepted
- **Date:** 2026-11-12

## Context

Remote access ran through a `wg-easy` container. It had been crash-looping for weeks
(over 17,000 restarts): a newer image version rejects the plain `PASSWORD`
environment variable and requires `PASSWORD_HASH`. The FRITZ!Box router supports
WireGuard natively since FRITZ!OS 7.50.

## Decision

Use the FRITZ!Box's built-in WireGuard server and remove `wg-easy`.

Client configuration: full tunnel (`AllowedIPs = 0.0.0.0/0`), DNS = FRITZ!Box.
VPN clients receive addresses from the LAN range (192.168.1.2xx), so no extra
subnet has to be allowed anywhere.

## Consequences

- ✅ One container less to maintain, update and secure
- ✅ VPN keeps working while the Docker host is down or being rebuilt — exactly
  when remote access matters most
- ✅ WireGuard UDP port is handled by the router, not forwarded to the host
- ➖ VPN configuration lives in the router UI, not in this repo
