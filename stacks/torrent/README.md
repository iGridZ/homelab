# torrent

Torrent client for MyAnonamouse (MAM), fully behind ProtonVPN.

| Container | Role |
|---|---|
| `gluetun` | ProtonVPN (WireGuard), kill-switch firewall, port forwarding (NAT-PMP) |
| `qbittorrent` | qBittorrent 5.2.3 with libtorrent v1, runs inside gluetun's network |
| `mousehole` | Keeps the MAM dynamic-seedbox IP up to date, also inside gluetun's network |

| | |
|---|---|
| Access | qBittorrent `http://192.168.1.245:8085`, mousehole `http://192.168.1.245:5010` – LAN/VPN only |
| Data | `/media/share/mam` (NAS, NFS) → `/data/mam` in qBittorrent |
| Config | `/docker/configs/gluetun`, `/docker/configs/qbittorrent`, volume `mousehole` |
| Secrets | Proton WireGuard key, mousehole password in `.env` |

```mermaid
flowchart LR
    subgraph g[gluetun network namespace]
        qb[qBittorrent]
        mh[mousehole]
        gl[gluetun<br/>WireGuard + firewall]
    end
    qb --> gl
    mh --> gl
    gl == "ProtonVPN tunnel" ==> proton((ProtonVPN<br/>P2P server))
    proton --> mam((MAM tracker + peers))
    gl -. "forwarded port → qBittorrent API" .-> qb
    lan((LAN / WireGuard)) -- ":8085 / :5010" --> gl
```

## Why it is built like this

- **One IP for MAM.** qBittorrent and mousehole use `network_mode: service:gluetun`,
  so the tracker and the dynamic-seedbox API always see the same VPN IP.
- **Connectable.** gluetun gets a forwarded port from ProtonVPN and sets it as
  qBittorrent's listen port via the API (up command), binding qBittorrent to the VPN
  interface. On reconnect the new port is set automatically.
- **No leaks.** If the VPN is down, gluetun's firewall blocks all traffic.
- **libtorrent v1:** lower RAM use and more reliable when seeding from NFS than v2.
- **Web UI port 8085 on both sides.** qBittorrent's CSRF check compares the browser's
  port with its own; a mapping like `8085:8080` answers every request with
  `Unauthorized`. `WEBUI_PORT`, the port mapping and the gluetun up/down command
  must all use the same port.

## First setup

1. NAS: create `media/mam`. Host: add to `/etc/fstab` and mount
   `192.168.1.250:/volume1/media/mam /media/share/mam nfs rw,vers=3,_netdev,nofail 0 0`
2. ProtonVPN: WireGuard config with **NAT-PMP (Port Forwarding)**, P2P server → copy the private key
3. `cp .env.example .env && chmod 600 .env`, fill in
4. `docker compose up -d`
5. qBittorrent (`:8085`): log in with the temporary password from `docker logs qbittorrent`,
   then set a password, and under *Web UI* tick **Bypass authentication for clients on
   localhost** (needed by gluetun's port update). Default save path: `/data/mam`.
6. mousehole (`:5010`): log in, paste the MAM cookie.
7. In MAM, the seedbox / connectable status should turn green.

## Checks

```bash
docker logs gluetun 2>&1 | grep -iE "port forwarded|public ip"   # VPN IP + forwarded port
docker exec gluetun wget -qO- https://ipinfo.io/ip                  # must NOT be the home IP
```

qBittorrent → *Settings → Connection*: listen port = forwarded port, interface = `tun0`.

CLI alternative: `./run.sh`
