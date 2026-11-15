# jellyfin

[Jellyfin](https://jellyfin.org) media server for movies (Radarr) and series (Sonarr).

| | |
|---|---|
| Container | `jellyfin` |
| Access | LAN: `http://192.168.1.245:8096` (TVs and apps) · public: `<media-domain>` via NPM |
| Data | config `/docker/configs/jellyfin`, cache `/docker/configs/jellyfin-cache`, media on the NAS |
| Secrets | none |

## Notes

- **Port 8096 stays published**: devices at home connect by IP.
- **Cache** is a fixed folder, not an anonymous volume, so recreating the container
  no longer leaves orphaned volumes. It only holds rebuildable data (images,
  metadata, transcode temp files) and does not need a backup.
- **iGPU** (`/dev/dri/renderD128`) is passed in for hardware transcoding. The AMD R7E
  decodes H.264/HEVC and encodes H.264 via VA-API. It is only used once enabled in
  *Dashboard → Playback → Transcoding → Hardware acceleration: VAAPI*,
  device `/dev/dri/renderD128`.

## Deploy

```bash
sudo mkdir -p /docker/configs/jellyfin-cache
docker rm -f jellyfin
cd ~/homelab/stacks/jellyfin
docker compose up -d
docker compose ps                 # (healthy) after ~1 min
```

Then remove the old anonymous cache volume (`docker volume ls -f dangling=true`).

CLI alternative: `./run.sh`
