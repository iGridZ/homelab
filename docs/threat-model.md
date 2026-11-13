# Threat model

A short, honest threat model for a single-host homelab. It decides which security
measures are worth their complexity.

## What is worth protecting

| Asset | Why it matters |
|---|---|
| Vaultwarden vault | All my passwords. Encrypted client-side, but losing the data or the service hurts |
| The Docker host | Access to the Docker socket is effectively root on the machine |
| The home network behind it | A compromised host is a foothold into every device on the LAN |
| Media library on the NAS | Large, slow to rebuild |
| Service configs (`/docker`) | Years of tuning; the reason this repo exists |

## Who realistically attacks

- **Automated scanners and bots** (primary threat). Every public IP is scanned within
  minutes. They try default credentials, known CVEs in popular self-hosted apps
  (Portainer, *arr apps, download clients) and exposed admin panels.
- **Credential stuffing** against public login pages.
- **Supply chain**: a compromised or abandoned container image.
- **Me**: misconfiguration, a forgotten port forward, an accidentally committed secret.

Out of scope: targeted, well-resourced attackers and physical access.

## Attack surface

| Entry point | Exposure | Mitigation |
|---|---|---|
| NPM :80/:443 | Internet | HTTPS only, every public app has its own login, admin panels have no hostname |
| TeamSpeak :42069/udp, :30033/tcp | Internet | Vendor image, kept updated |
| WireGuard (FRITZ!Box) | Internet | Key-based, handled by the router |
| SSH :22 | LAN / VPN | FIDO2 hardware keys only, no passwords, no root ([ADR 0003](decisions/0003-ssh-fido2-yubikey.md)) |
| Published container ports | LAN | Being removed for everything reached via NPM |
| Container images | Supply chain | Moving from `:latest` to pinned versions + automated update PRs |
| This repository | Public | Secrets only in untracked `.env` files, gitleaks in CI |

## Layers (defense in depth)

| # | Layer | Status |
|---|---|---|
| 1 | Perimeter: minimal port forwards, admin via VPN | ✅ done |
| 2 | SSH: hardware keys only | ✅ done |
| 3 | Secrets out of scripts and git | ✅ first pass done (leaked tokens rotated, old scripts archived) |
| 4 | Backups with a tested restore | ⏳ planned (dedicated USB SSD) |
| 5 | Container hardening: pinned images, no `--privileged`, `no-new-privileges`, dropped capabilities | ⏳ during Compose migration |
| 6 | Network segmentation: proxy network vs. backend networks | ⏳ during Compose migration |
| 7 | Intrusion prevention: CrowdSec on the NPM logs | 💡 idea |
| 8 | Patch management: Renovate PRs, image scanning in CI | 💡 idea |
| 9 | Monitoring and alerting | 🔄 Beszel running, alerts not yet configured |
