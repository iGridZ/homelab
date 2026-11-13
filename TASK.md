# TASK.md – homelab

Status: 2026-11-13. Updated after every work session.
Background and reasoning: [docs/decisions/](docs/decisions/), [docs/threat-model.md](docs/threat-model.md).

## Open

### Next up
- [ ] SSH: add YubiKey 1, test both keys, apply `10-hardening.conf` (at home, console as fallback). Decision: SSH login always with a FIDO2 key, no other key types — [runbook](docs/runbooks/ssh-fido2-yubikey.md)
- [ ] Remove `wg-easy`, `watchtower`, `playwright-chrome`
- [ ] `portainer_agent`: check environment type in Portainer (socket vs. agent), remove if unused
- [ ] Delete the unused Portainer certificate in NPM; remove `portainer.<domain>` from the DDNS `DOMAINS` list and delete its record in Cloudflare
- [ ] Disconnect Portainer from the `media` network (no proxy host anymore)
- [ ] Disable the leftover `certbot.timer` (NPM handles certificates)
- [ ] Rotate the Cloudflare tunnel token (or delete the unused tunnel) and the Beszel agent token
- [ ] Check the Cloudflare API token scope (DNS edit, own zones only)
- [ ] Archive the old `docker run` scripts in `~` that are no longer used; `chmod 600` the rest
- [ ] Scan existing repos (GrowLog, GrowView) with gitleaks
- [ ] Decide on port forward 8555 (go2rtc WebRTC): only needed if the cam is watched from outside
- [ ] Fill in the proxy host table in `docs/network.md` from the NPM UI
- [ ] Check login on every proxied app (changedetection has none by default)

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

### 2026-11-13 – feature/repo-skeleton
- [x] Repo structure, README with architecture, threat model, network doc, ADRs 0001–0004, SSH runbook
- [x] CI: shellcheck, yamllint, compose validation, gitleaks
- [x] `scripts/inventory.sh` (read-only host snapshot with secret redaction)
- [x] SSH login with YubiKey 2 (`ed25519-sk`, resident, PIN required) tested
- [x] Decision: keep Nginx Proxy Manager ([ADR 0004](docs/decisions/0004-keep-nginx-proxy-manager.md))

### 2026-11-12 – security first pass (on the host)
- [x] Removed router forward 8443 → Portainer 9443; admin panels LAN/VPN-only ([ADR 0001](docs/decisions/0001-admin-panels-vpn-only.md))
- [x] FRITZ!Box WireGuard set up (full tunnel) ([ADR 0002](docs/decisions/0002-fritzbox-wireguard.md))
- [x] Crontab cleaned (daily reboot and screen jobs removed)
- [x] Portainer proxy host removed from NPM
