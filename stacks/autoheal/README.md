# autoheal

[willfarrell/autoheal](https://github.com/willfarrell/docker-autoheal) restarts any
container whose healthcheck turns `unhealthy`.

| | |
|---|---|
| Container | `autoheal` |
| Access | none (no network, no UI) |
| Data | none |
| Secrets | none |

## Notes

- `AUTOHEAL_CONTAINER_LABEL=all`: every container with a healthcheck is watched,
  no label needed. Containers without a healthcheck are ignored.
- `network_mode: none`: it only needs the Docker socket.
- The socket is mounted read-write because autoheal restarts containers.
  Any container with the socket effectively has root on the host, so this is a
  candidate for a socket proxy later.

## Updating (digest pin)

Upstream publishes no version tags, so the image is pinned by digest:

```bash
docker pull willfarrell/autoheal:latest
docker image inspect --format '{{index .RepoDigests 0}}' willfarrell/autoheal:latest
```

Put the `sha256:…` part into `compose.yaml` and `run.sh`, then open a PR.

## Deploy

```bash
cd ~/homelab/stacks/autoheal
docker rm -f autoheal        # only when migrating from the old docker-run container
docker compose up -d
```

CLI alternative: `./run.sh`
