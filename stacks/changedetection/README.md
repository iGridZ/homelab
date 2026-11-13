# changedetection

[changedetection.io](https://github.com/dgtlmoon/changedetection.io) watches websites
for changes. [sockpuppetbrowser](https://github.com/dgtlmoon/sockpuppetbrowser) is an
optional headless Chrome for JavaScript-heavy pages.

| | |
|---|---|
| Containers | `changedetection`, optional `playwright-chrome` (profile `browser`) |
| Access | `http://192.168.1.245:5001` – LAN/VPN only, not proxied |
| Data | `/docker/changedetection` (bind mount) |
| Secrets | none (set a UI password under *Settings* anyway) |

## Notes

- The browser is a **Compose profile**: defined here, but only started on demand.
  Its log showed `Total processed: 0`, so no watch used it so far.
- Watches set to fetch with "Playwright/Chrome" fail while the browser is not running;
  plain HTTP watches are unaffected.
- Both services share the stack's own network. The browser has no published port
  and is not on the proxy network, so only changedetection can reach it.
- `mem_limit: 1g` keeps a runaway Chrome from starving the thin client.

## Deploy (migration from the old `change` container)

The new image is a version upgrade and migrates the datastore, so back it up first:

```bash
sudo cp -a /docker/changedetection /docker/changedetection.bak-$(date +%F)
docker rm -f change playwright-chrome
cd ~/homelab/stacks/changedetection
docker compose up -d                      # or: docker compose --profile browser up -d
docker compose ps
```

Rollback: `docker compose down`, restore the backup folder, `bash ~/changedetection.sh`.

CLI alternative: `./run.sh` or `./run.sh --browser`
