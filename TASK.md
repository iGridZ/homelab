# TASK.md – homelab

Status: 2026-11-16. Updated after every work session.
Background and reasoning: [docs/decisions/](docs/decisions/), [docs/threat-model.md](docs/threat-model.md).

## Open

### Next up
- [ ] Release: `dev` → `main` (PRs #24–#29: teamspeak, portainer, growlog stacks + TASK.md)
- [ ] GrowLog repo PR #1 (`CLAUDE.md`: deployment via compose in this repo) waiting for merge
- [ ] Archive old run scripts in `~` (replaced by stacks): `beszel.sh`, `beszel_agent.sh`, `autoheal.sh`, `ddns.sh`, `changedetection.sh`, `sonarr.sh`, `radarr.sh`, `sab.sh`, `frigate.sh`, `go2rtx.sh`, `jellyfin.sh`, `ts6.sh`, `crafty.sh`, `growlog/growlog.sh`, old fetcher script
- [ ] Scan existing repos (GrowLog, vivosun-fetcher) with gitleaks

### Remaining migrations
- [ ] twitch-old-old (kept): stack with digest-pinned image; `run.py` + `cookies/` stay on the host; port 5000 needed?
- [ ] alert2 (kept): fork upstream `raftheunis87/tradingview-to-telegram-webhook-bot` → own repo, Node 14 → 22, Telegram token/chat id via `.env`, CI `dev`/`latest` to GHCR, then stack. Webhook not reachable right now (proxy host removed); if public again: NPM access list with TradingView webhook IPs + secret in the alert payload
- [ ] After backup adapter: Vaultwarden + NPM stacks

### Planned
- [ ] Delete `/docker/configs/radarr.bak-6.4.4` after a few days without problems
- [ ] Backups: dedicated 256 GB SATA SSD via USB → restic, nightly systemd timer, documented restore test. **On hold**: USB-SATA adapters lost; buy one for 2.5" + 3.5" with its own 12 V power supply. Until then: local `cp -a …bak` before every migration
- [ ] Self-hosted GitHub Actions runner on the host: deploy changed stacks on merge to `main` (push to `main` only, no PR jobs on the runner)
- [ ] Renovate for image update PRs (replaces watchtower)
- [ ] Plan Ubuntu 22.04 → 24.04 (standard support ends 2027-04)
- [ ] Frigate: ~27 % CPU is likely object detection (decoding already on the iGPU) → check detector, detect fps/resolution

### Ideas (not decided)
- [ ] GrowLog CI: also build a `:dev` image (currently only `:latest` from `main`)
- [ ] Jellyfin VAAPI: video transcoding is disabled per user (clients decode HEVC), only remux/audio transcoding is used; VAAPI would still speed up trickplay/thumbnail extraction
- [ ] `sudo` with YubiKey touch (pam-u2f)
- [ ] CrowdSec on the NPM logs
- [ ] Beszel alerts to Discord/Telegram
- [ ] Trivy image scan in CI

## Done

### 2026-11-17 – radarr 7
- [x] Radarr 6.4.4 → 7.0.3.10918 (stable, not nightly): config backed up first, DB migration 243 ok, search → SABnzbd works
- [x] Radarr *Allowed Hosts* set (domain, container name, localhost)
- [x] CI now also runs on `chore/`, `fix/`, `docs/`, `ci/` branches

### 2026-11-16 – camera: single stream source
- [x] Fetcher writes credentials only into go2rtc (`rtsp-cam`); `growcam` derived without audio; Frigate pulls from go2rtc and holds no camera password
- [x] Verified: Frigate + go2rtc live, one fetcher log line, recordings without audio

### Releases to `main`
- [x] #5 repo skeleton, CI, Beszel · #9 autoheal, cloudflare-ddns, SSH with two YubiKeys · #15 changedetection, arr, proxy host review · #19 camera stack, host config · #23 Jellyfin, SMART results

### 2026-11-16 – compose migration status
- [x] 10 stacks in the repo (16 containers), no `privileged` containers left
- [x] Crafty removed; twitch-old-old and alert2 kept (decision)
- [x] TeamSpeak re-created from `stacks/teamspeak` (not started)
- [x] GrowLog running from `stacks/growlog`
- [x] Old anonymous Jellyfin cache volume removed
- [x] Host step 5: lxd snap removed, unused services disabled
- [x] Drawer drive SMART check done

### 2026-11-16 – stacks/portainer
- [x] Portainer 2.45.3 deployed from `dev`: port 8000 closed, 9443 LAN/VPN by IP, data volume reused

### 2026-11-15 – stacks/jellyfin
- [x] Jellyfin 12.4 deployed from `dev`: works via LAN IP:8096 and domain; cache in fixed folder; iGPU passed in (not enabled)

### 2026-11-15 – spare drives
- [x] sdb (1 TB WD white label, 3.5"): 2 extended self-tests passed, 0 errors → usable as backup drive (second / offline copy); needs a USB-SATA adapter with its own 12 V power supply
- [x] sda (WD Red 2 TB): ruled out (71 UNC errors, 3 failed self-tests)

### 2026-11-13 – host tuning (feature/host-config)
- [x] `/etc/docker/daemon.json`: global log rotation + `live-restore` (containers survived the daemon restart)
- [x] System up to date (apt)
- [x] zram (zstd, 50 %, priority 100) in front of the SSD swap file
- [x] Frigate already uses VA-API automatically; iGPU decodes H.264 + HEVC
- [x] Host config files in `host/`, runbook `docs/runbooks/host-setup.md`

### 2026-11-13 – stacks/camera
- [x] go2rtc (no `privileged`, no capabilities), Frigate, vivosun-fetcher (GHCR) deployed from `dev`; live view OK in Frigate + go2rtc
- [x] vivosun-fetcher in its own repo with CI: `:dev` from `dev`, `:latest` from `main` (fetcher PRs #1, #2), GHCR package public
- [x] Host ports 1984, 8554, 8556, 8557, 8971, 8555/udp closed; only 8555/tcp (WebRTC) remains
- [x] GrowView removed (no longer used)
- [x] `onlyplants` viewer works from outside (5G, PWA)

### 2026-11-13 – stacks/arr
- [x] Sonarr, Radarr, SABnzbd deployed from `dev`; host ports 7878/8989/8080 closed, download client host `sabnzbd:8080`

### 2026-11-13 – stacks/changedetection
- [x] changedetection 0.60.10 deployed from `dev` (upgrade, datastore backed up first), healthy; browser as optional profile

### 2026-11-13 – proxy host review
- [x] Proxy host table in `docs/network.md` (domains as placeholders)
- [x] `onlyplants` (go2rtc :1984) was fully public without auth → path filter in NPM: only `stream.html?src=growcam` + websocket
- [x] Logins confirmed: SABnzbd, Sonarr, Radarr, Beszel; changedetection + Crafty are not proxied (LAN only)
- [x] Beszel stays public via `mon.<domain>` with its own login (decision)
- [x] `alert` proxy host removed (bot had no secret check)

### 2026-11-13 – SSH second key
- [x] YubiKey 1 added; both keys work (PC prefers YubiKey 1, notebook YubiKey 2)

### 2026-11-13 – stacks/autoheal, stacks/cloudflare-ddns
- [x] cloudflare-ddns 1.17.1 deployed from `dev`: non-root, read-only, all caps dropped; records up to date
- [x] autoheal deployed from `dev` (digest-pinned, no network)

### 2026-11-13 – stacks/beszel
- [x] Beszel hub + agent migrated to Compose (pinned 0.21.1, existing volumes reused, secrets in `.env`), deployed from `dev` and running on the host

### 2026-11-13 – feature/repo-skeleton
- [x] Repo structure, README with architecture, threat model, network doc, ADRs 0001–0004, SSH runbook
- [x] CI: shellcheck, yamllint, compose validation, gitleaks
- [x] `scripts/inventory.sh` (read-only host snapshot with secret redaction)
- [x] SSH login with YubiKey 2 (`ed25519-sk`, resident, PIN required) tested
- [x] sshd hardened: FIDO2 keys only, no passwords, no root login (`10-hardening.conf`, verified with `sshd -T`)
- [x] Client `~/.ssh/config` alias: `ssh rock`
- [x] Removed `wg-easy`, `watchtower`, `portainer_agent` (Portainer uses the local socket); `playwright-chrome` is kept
- [x] Portainer disconnected from `media`; Portainer certificate, DDNS entry and DNS record removed
- [x] `certbot.timer` disabled
- [x] Cloudflare: unused tunnel/token cleaned up, API token scope checked; Beszel agent token rotated
- [x] Old `docker run` scripts archived to `~/archive` (700), remaining scripts `chmod 600`
- [x] 3 orphaned anonymous Jellyfin cache volumes identified for removal (Jellyfin stack will use a fixed cache bind mount)
- [x] `docker image prune` + `builder prune`: images 22.1 → 18.2 GB, build cache 4.5 GB → 0.7 GB
- [x] Decision: keep Nginx Proxy Manager ([ADR 0004](docs/decisions/0004-keep-nginx-proxy-manager.md))

### 2026-11-12 – security first pass (on the host)
- [x] Removed router forward 8443 → Portainer 9443; admin panels LAN/VPN-only ([ADR 0001](docs/decisions/0001-admin-panels-vpn-only.md))
- [x] FRITZ!Box WireGuard set up (full tunnel) ([ADR 0002](docs/decisions/0002-fritzbox-wireguard.md))
- [x] Crontab cleaned (daily reboot and screen jobs removed)
- [x] Portainer proxy host removed from NPM
