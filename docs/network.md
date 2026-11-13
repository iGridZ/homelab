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
placeholders `<domain>` (main domain) and `<media-domain>` (Jellyfin).

| Hostname | Forward to | Access | Protection |
|---|---|---|---|
| `<media-domain>` | `http://jellyfin:8096` | Public | Jellyfin login |
| `vw.<domain>` | `http://192.168.1.245:8081` | Public | Vaultwarden login (master password) |
| `growlog.<domain>` | `http://growlog:8087` | Public | GrowLog login |
| `frigate.<domain>` | `https://frigate:8971` | Public | Frigate login (authenticated port, never `:5000`) |
| `sonarr.<domain>` | `http://sonarr:8989` | Public | Forms login |
| `radarr.<domain>` | `http://radarr:7878` | Public | Forms login |
| `sabnzbd.<domain>` | `http://sabnzbd:8080` | Public | SABnzbd login |
| `mon.<domain>` | `http://beszel:8090` | Public | Beszel login |
| `onlyplants.<domain>` | `http://go2rtc:1984` | Public, **path-filtered** | Only the `growcam` viewer is reachable, see below |
| `alert.<domain>` | `http://192.168.1.245:8082` | Public (TradingView webhooks) | ⚠️ no secret check yet |

Not proxied (LAN/VPN only): Portainer, NPM admin, changedetection, Crafty.

### onlyplants: public camera viewer without exposing go2rtc

go2rtc's API on `:1984` has no authentication and can create streams with `exec:`
sources, so it must never be fully public. The proxy host only lets through what the
viewer page needs (Websockets Support enabled, Advanced config):

```nginx
# Only the public stream page for "growcam" — everything else in go2rtc is blocked
set $deny 1;
if ($uri ~ "^/(video-stream|video-rtc)\.js$") { set $deny 0; }
if ($request_uri ~ "^/(stream\.html|api/ws)\?src=growcam(&|$)") { set $deny 0; }
if ($deny) { return 403; }
```

Result: `/stream.html?src=growcam` works; `/`, `/api/streams`, `/api/config` and every
other stream return `403`.

### Lesson learned: IP access lists and hairpin NAT

Requests to a public hostname from inside the LAN or over WireGuard are hairpinned
by the FRITZ!Box and reach NPM with the **public IP** as source. IP-based access
lists therefore cannot distinguish "home" from "internet" for proxied hostnames.
Consequences: admin tools get no hostname at all ([ADR 0001](decisions/0001-admin-panels-vpn-only.md)),
and public hosts rely on app logins, HTTP basic auth or path filters. IP allow-lists
only work for callers that really come from outside (e.g. webhook providers).

## Docker networks

| Network | Members | Purpose |
|---|---|---|
| `media` | NPM and everything it proxies, plus the camera stack | Lets NPM reach apps by container name (`http://jellyfin:8096`) |
| `bridge` (default) | Remaining standalone containers | Legacy — to be cleaned up during the Compose migration |
| `host` | cloudflare-ddns, beszel-agent | Need the host's network view |

**Target state** (Compose migration): a dedicated `proxy` network that only contains
NPM and the apps it serves, separate backend networks per stack, and no published
ports for anything that is only reached through NPM.
