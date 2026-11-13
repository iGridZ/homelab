# 0001 – Admin panels are LAN/VPN-only, without a public hostname

- **Status:** Accepted
- **Date:** 2026-11-12

## Context

Portainer was reachable from the internet through a router port forward
(external 8443 → internal 9443). Portainer controls the Docker socket, so a
compromised login equals root on the host. Admin panels are a favourite target of
automated scanners.

A first fix — a public hostname in Nginx Proxy Manager protected by an access list
(allow `192.168.1.0/24`, deny all) — did not work: requests from the LAN and from
WireGuard clients to the public hostname are hairpinned by the FRITZ!Box and arrive
with the router's public IP as source, so the access list rejected legitimate
clients with `403`. Fixing that would need split-horizon DNS (a local resolver such
as AdGuard Home) only for this purpose.

## Decision

Admin panels (Portainer, the NPM admin UI) get **no public hostname and no port
forward**. They are reached directly by LAN IP and port, from home or through the
FRITZ!Box WireGuard VPN ([ADR 0002](0002-fritzbox-wireguard.md)).

- Removed the router forward 8443 → 9443
- Removed the Portainer proxy host and its certificate from NPM
- Removed the Portainer DNS record from Cloudflare

## Consequences

- ✅ Zero internet exposure for the most dangerous interfaces
- ✅ No extra moving parts (no local DNS server needed)
- ➖ Portainer uses its self-signed certificate: `https://192.168.1.245:9443` must be
  typed with `https://` and the browser warning accepted once
- ➖ Admin access from outside requires the VPN to be connected
