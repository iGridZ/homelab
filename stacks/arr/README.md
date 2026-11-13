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
