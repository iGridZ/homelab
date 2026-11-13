# TASK.md – homelab

Status: 2026-11-13. Updated after every work session.
Background and reasoning: [docs/decisions/](docs/decisions/), [docs/threat-model.md](docs/threat-model.md).

## Open

### Next up
- [ ] Archive `~/autoheal.sh` and `~/ddns.sh` (replaced by stacks)
- [ ] Archive `~/beszel.sh` and `~/beszel_agent.sh` (replaced by `stacks/beszel`)
- [ ] Check SMART values + long self-test of the spare HDDs (PC + drawer) with `smartctl -x`; decide which drive is usable for backups
- [ ] Scan existing repos (GrowLog, GrowView) with gitleaks
- [ ] TeamSpeak: currently stopped on purpose (Erik starts it later); restart policy is `no` → `unless-stopped`
- [ ] playwright-chrome (kept): exited since 2026-11-01, check why and whether changedetection can reach it
- [ ] Decide on port forward 8555 (go2rtc WebRTC): only needed if the cam is watched from outside
- [ ] `alert` (TradingView bot): restrict to TradingView webhook IPs via NPM access list (deny all others), later add a secret in the alert payload

### Planned
- [ ] Backups: dedicated 256 GB SATA SSD via USB → restic, nightly systemd timer, documented restore test
- [ ] Compose migration, one stack per PR, least critical first: pinned images, no published ports behind NPM, `no-new-privileges`, no `privileged` (go2rtc)
- [ ] `/etc/docker/daemon.json`: global log rotation
- [ ] Self-hosted GitHub Actions runner on the host: deploy changed stacks on merge to `main` (push to `main` only, no PR jobs on the runner)
- [ ] Renovate for image update PRs (replaces watchtower)
- [ ] Apt updates (46 pending) + plan Ubuntu 22.04 → 24.04
- [ ] Performance: zram + lower swappiness, check Frigate hardware decoding (VA-API), `docker builder prune`, disable unused services (ModemManager, snap/lxd)

### Ideas (not decided)
- [ ] `sudo` with YubiKey touch (pam-u2f)
- [ ] CrowdSec on the NPM logs
- [ ] Beszel alerts to Discord/Telegram
- [ ] Trivy image scan in CI

## Done

### 2026-11-13 – proxy host review
- [x] Proxy host table in `docs/network.md` (domains as placeholders)
- [x] `onlyplants` (go2rtc :1984) was fully public without auth → path filter in NPM: only `stream.html?src=growcam` + websocket
- [x] Logins confirmed: SABnzbd, Sonarr, Radarr, Beszel; changedetection + Crafty are not proxied (LAN only)
- [x] Beszel stays public via `mon.<domain>` with its own login (decision)

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
