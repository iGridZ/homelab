# arr

Media automation: [Sonarr](https://sonarr.tv) (series), [Radarr](https://radarr.video)
(movies) and [SABnzbd](https://sabnzbd.org) (Usenet downloads).

| | |
|---|---|
| Containers | `sonarr`, `radarr`, `sabnzbd` |
| Access | `sonarr.<domain>`, `radarr.<domain>`, `sabnzbd.<domain>` via NPM, each with its own login |
| Data | configs in `/docker/configs/<app>`, media on the NAS (`/media/share`, NFS), downloads on the local SSD |
| Secrets | none in the stack (API keys live in each app's config) |

## Notes

- **No published ports.** NPM proxies by container name on the `media` network.
  Sonarr and Radarr use `sabnzbd:8080` as download client host (not the host IP).
- Images are pinned to the versions that were running at migration time.
  Updating = change the tag here, open a PR, redeploy (instead of pulling `latest`
  in Portainer), so every update is visible in the git history.
- One timezone for all three (`Europe/Berlin`); before the migration they used three
  different ones.

## Updates

Major updates (e.g. Radarr 6 → 7) run one-way database migrations:

1. Branch `chore/<app>-<version>`, change the tag in `compose.yaml` **and** `run.sh`
2. PR → `dev`, read the changelog (breaking changes, API changes)
3. Backup: *System → Backup → Backup Now* and `sudo cp -a /docker/configs/<app> /docker/configs/<app>.bak-<old-version>`
4. `docker compose pull <app> && docker compose up -d <app>`, watch `docker logs -f <app>` until the migration is done
5. Check UI, download client + indexer tests, one search, API consumers (StaxRip script)
6. Rollback: stop, restore the `.bak` folder, old tag, `up -d`

Use release tags only, never `nightly`/`testing`. Radarr 7+ also wants *Allowed Hosts*
(Settings → General → Host): `<app>.<domain>, <app>, localhost`.

## Deploy

```bash
docker rm -f sonarr radarr sabnzbd
cd ~/homelab/stacks/arr
docker compose up -d
```

Check: all three domains load, and in Sonarr/Radarr *Settings → Download Clients →
SABnzbd → Test* is green.

Rollback: `docker compose down`, then `bash ~/sonarr.sh ~/radarr.sh ~/sab.sh`
(one at a time).

CLI alternative: `./run.sh`
