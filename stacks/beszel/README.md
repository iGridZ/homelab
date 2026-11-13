# beszel

[Beszel](https://github.com/henrygd/beszel) – lightweight monitoring for the host and
all containers (CPU, RAM, disk, network, per-container stats).

| | |
|---|---|
| Containers | `beszel` (hub, web UI), `beszel-agent` (collector) |
| Access | `http://192.168.1.245:8090` – LAN/VPN only |
| Data | Docker volumes `beszel_data`, `beszel_agent_data` (pre-existing, `external`) |
| Secrets | `BESZEL_AGENT_KEY`, `BESZEL_AGENT_TOKEN` in `.env` |

## Notes

- The agent runs with `network_mode: host` to report real interface statistics.
- The Docker socket is mounted **read-only**. Read-only only stops writes to the socket
  file, not API calls through it, so a socket proxy is the planned next step.
- Both images are pinned; update both tags together (hub and agent must match).

## Deploy

```bash
cd ~/homelab/stacks/beszel
cp .env.example .env && nano .env     # first time only
docker rm -f beszel beszel-agent      # only when migrating from the old docker-run containers
docker compose up -d
docker compose ps                     # both should become "healthy" within ~2 min
```

CLI alternative: `./run.sh`
