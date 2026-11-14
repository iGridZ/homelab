# host

Configuration files of the Docker host itself (not of containers). Each file maps 1:1
to a path on the host; the setup procedure is in
[docs/runbooks/host-setup.md](../docs/runbooks/host-setup.md).

| File | Host path | Purpose |
|---|---|---|
| `docker/daemon.json` | `/etc/docker/daemon.json` | Log rotation for all containers, `live-restore` |
| `ssh/10-hardening.conf` | `/etc/ssh/sshd_config.d/10-hardening.conf` | FIDO2-only SSH ([ADR 0003](../docs/decisions/0003-ssh-fido2-yubikey.md)) |
| `zram/zramswap` | `/etc/default/zramswap` | Compressed swap in RAM |
