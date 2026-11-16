# growlog

[GrowLog](https://github.com/iGridZ/growlog) – my own grow journal (Flask + SQLite PWA).
The image is built and tested by that repo's GitHub Actions and published to GHCR.

| | |
|---|---|
| Container | `growlog` |
| Access | `growlog.<domain>` via NPM (own login, multi-user) |
| Data | `/docker/data/growlog/growlog.db` (SQLite) |
| Secrets | none in the stack (users live in the database) |

## Notes

- No published port: NPM reaches `growlog:8087` on the `media` network.
- Read-only root filesystem, only `/data` and a `/tmp` tmpfs are writable;
  all capabilities dropped.
- Feature testing stays in the GrowLog repo's own workflow (test container on
  port 8088 with a data copy).

## Deploy

```bash
sudo cp -a /docker/data/growlog /docker/data/growlog.bak-$(date +%F)
docker rm -f growlog
cd ~/homelab/stacks/growlog
docker compose up -d
docker compose logs --tail 20      # gunicorn "Booting worker"
```

Update to a new GrowLog release: `docker compose pull && docker compose up -d`.

CLI alternative: `./run.sh`
