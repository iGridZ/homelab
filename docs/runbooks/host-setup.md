# Runbook: host setup and tuning

Applies the files in [`host/`](../../host/) to the t630 (Ubuntu 22.04). Every step is
idempotent and can be re-run.

## 1. Docker daemon: log rotation + live-restore

```bash
sudo cp host/docker/daemon.json /etc/docker/daemon.json
sudo systemctl reload docker     # enables live-restore first ...
sudo systemctl restart docker    # ... so this restart keeps containers running
docker info --format '{{.LoggingDriver}} live-restore={{.LiveRestoreEnabled}}'
```

- Log limits apply to containers created afterwards; the stacks set them explicitly too.
- `live-restore` keeps containers running while the daemon restarts (e.g. Docker updates).

## 2. Updates

```bash
sudo apt update && sudo apt full-upgrade -y
[ -f /var/run/reboot-required ] && sudo reboot
```

Security updates are installed automatically by `unattended-upgrades`.

## 3. zram

```bash
sudo apt install -y zram-tools
sudo cp host/zram/zramswap /etc/default/zramswap
sudo systemctl restart zramswap
swapon --show          # /dev/zram0 with priority 100, before /swap.img (-2)
```

With zram as the first swap device the default `vm.swappiness=60` stays: swapping into
compressed RAM is cheap and saves SSD writes.

## 4. SSH hardening

See [ssh-fido2-yubikey.md](ssh-fido2-yubikey.md). Config file: `host/ssh/10-hardening.conf`.

## 5. Remove unused services

The t630 is wired, has no modem, no SAN storage and runs containers with Docker only:

```bash
sudo snap remove lxd
sudo systemctl disable --now ModemManager multipathd multipathd.socket wpa_supplicant
sudo apt autoremove -y
```

## Checks

| Check | Expected |
|---|---|
| `docker info --format '{{.LiveRestoreEnabled}}'` | `true` |
| `swapon --show` | `zram0` priority 100 |
| `sudo sshd -T \| grep passwordauthentication` | `no` |
| `docker logs frigate 2>&1 \| grep hwaccel` | `Automatically detected vaapi hwaccel` |

## Hardware notes

- iGPU: AMD Radeon R7E (Carrizo), Mesa radeonsi VA-API driver. Hardware decode for
  H.264 and HEVC Main (`vainfo`), used automatically by Frigate.
