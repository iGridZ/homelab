# portainer

[Portainer](https://www.portainer.io) Business Edition – web UI for Docker.

| | |
|---|---|
| Container | `portainer` |
| Access | `https://192.168.1.245:9443` – LAN or WireGuard only ([ADR 0001](../../docs/decisions/0001-admin-panels-vpn-only.md)) |
| Data | Docker volume `portainer_data` (pre-existing, `external`) |
| Secrets | none in the stack (users and license live in the volume) |

## Notes

- **Read-mostly tool.** Stacks are deployed from this repo. Portainer shows them as
  "external" stacks; changing them in Portainer would make the host drift from git.
  Use it for logs, stats and restarts.
- Port 8000 (Edge agent tunnel) is no longer published: no Edge agents are used.
- It holds the Docker socket, i.e. root on the host. That is why it has no public
  hostname and no router forward.
- Own default network (not `media`): nothing needs to reach Portainer except the browser.

## Deploy

Run this over SSH, not from inside Portainer (it would remove itself mid-way):

```bash
docker rm -f portainer
cd ~/homelab/stacks/portainer
docker compose up -d
```

CLI alternative: `./run.sh`
