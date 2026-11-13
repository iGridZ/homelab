# cloudflare-ddns

[favonia/cloudflare-ddns](https://github.com/favonia/cloudflare-ddns) updates the
Cloudflare DNS records in `DOMAINS` whenever the home IP changes.

| | |
|---|---|
| Container | `cloudflare-ddns` |
| Access | none (no UI, outbound HTTPS only) |
| Data | none (stateless) |
| Secrets | `CLOUDFLARE_API_TOKEN`, `DOMAINS` in `.env` |

## Notes

- Hardened as recommended upstream: non-root user, read-only filesystem, all
  capabilities dropped, `no-new-privileges`.
- `PROXIED=false`: records point directly at the home IP (needed for TeamSpeak,
  which Cloudflare cannot proxy).
- The token only needs **Zone → DNS → Edit** on the listed zones.
- Removing a name from `DOMAINS` does **not** delete its record; delete it in the
  Cloudflare dashboard.
- Domains live in `.env` so they are not published in this repo.

## Deploy

```bash
cd ~/homelab/stacks/cloudflare-ddns
cp .env.example .env && chmod 600 .env && nano .env   # first time only
docker rm -f cloudflare-ddns   # only when migrating from the old docker-run container
docker compose up -d
docker compose logs -f         # should report the current IP and "already up to date"
```

CLI alternative: `./run.sh`
