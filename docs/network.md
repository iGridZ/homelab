# Network

## Addressing

| Device | Address | Role |
|---|---|---|
| FRITZ!Box | 192.168.1.254 | Router, DNS, perimeter firewall, WireGuard server |
| t630 (`rock`) | 192.168.1.245 | Docker host |
| Synology NAS | 192.168.1.250 | Media storage (NFS exports, media only — no backups) |
| WireGuard clients | 192.168.1.2xx | FRITZ!Box hands VPN clients addresses from the LAN range |

## Perimeter: router port forwards

Every forward needs a reason. Anything not in this table must not be forwarded.

| External port | Target | Service | Reason |
|---|---|---|---|
| 80/tcp | t630:80 | Nginx Proxy Manager | HTTP → HTTPS redirect, Let's Encrypt HTTP challenge |
| 443/tcp | t630:443 | Nginx Proxy Manager | All public web apps |
| 42069/udp | t630:42069 | TeamSpeak 6 voice | Not HTTP, cannot go through the proxy |
| 30033/tcp | t630:30033 | TeamSpeak 6 file transfer | Not HTTP |
| 8555 | t630:8555 | go2rtc WebRTC | **Under review** — only needed if the camera stream is shared outside the LAN |

Removed:

| Port | Was | Why removed | Date |
|---|---|---|---|
| 8443 → 9443 | Portainer | Docker admin UI (= root on the host) was reachable from the internet. Now VPN-only, see [ADR 0001](decisions/0001-admin-panels-vpn-only.md) | 2026-11-12 |

> Note: Docker publishes ports with its own iptables rules and bypasses host
> firewalls such as ufw. The router is the real perimeter today; inside the LAN,
> the fix is to stop publishing ports that only the proxy needs (see below).

## Access classes

| Class | How it is reached | Requirements |
|---|---|---|
| **Public web** | `https://<app>.<domain>` → NPM → container | HTTPS (Force SSL, HSTS), app has its own login |
| **Admin** | `https://192.168.1.245:<port>` from LAN or WireGuard | No public hostname, no port forward |
| **Direct** | Router port forward to a published container port | Non-HTTP protocol only, documented above |
| **Internal** | Docker network only | No published port |

Never proxy publicly: **go2rtc API (:1984)** and **Frigate's unauthenticated port (:5000)**
— both have no login. Frigate is only ever exposed via its authenticated port 8971.

## Proxy hosts (Nginx Proxy Manager)

NPM keeps its configuration in a database, so this table is the reviewed source of
truth ([ADR 0004](decisions/0004-keep-nginx-proxy-manager.md)). Hostnames use the
placeholder `<domain>`.

| Hostname | Forward to | Access | App login |
|---|---|---|---|
| _to be filled in from the NPM proxy host list_ | | | |

## Docker networks

| Network | Members | Purpose |
|---|---|---|
| `media` | NPM and everything it proxies, plus the camera stack | Lets NPM reach apps by container name (`http://jellyfin:8096`) |
| `bridge` (default) | Remaining standalone containers | Legacy — to be cleaned up during the Compose migration |
| `host` | cloudflare-ddns, beszel-agent | Need the host's network view |

**Target state** (Compose migration): a dedicated `proxy` network that only contains
NPM and the apps it serves, separate backend networks per stack, and no published
ports for anything that is only reached through NPM.
