# camera

Grow tent camera (VIVOSUN GrowCam C4): live streaming and the public viewer.

| | |
|---|---|
| Containers | `go2rtc`, `vivosun-fetcher` |
| Access | viewer: `onlyplants.<domain>/stream.html?src=growcam` |
| Data | config `/docker/config/go2rtc` |
| Secrets | Vivosun login in `.env`; camera RTSP credentials only in the configs on the host |

```mermaid
flowchart LR
    vivo[(Vivosun cloud)] --> fetch[vivosun-fetcher]
    fetch -- "camera credentials → stream rtsp-cam" --> g2r[go2rtc]
    cam[GrowCam C4<br/>RTSP :554] -->|pull, audio + video| g2r
    g2r -- "growcam = rtsp-cam?video (video only)<br/>WebRTC :8555 / MSE via NPM" --> friends((Viewers))
```

## Notes

- **go2rtc runs without `privileged`** and with all capabilities dropped. Its config
  only relays RTSP; nothing needs host hardware.
- **One source for the camera:** the fetcher writes the credentials only into go2rtc
  (stream `rtsp-cam`). `growcam` is derived from it without audio and contains no
  camera password.
- **No Frigate (removed 2026-11-23).** Recording and object detection gave no benefit
  for a grow tent cam. go2rtc alone is the viewer (WebRTC).
- **Only port 8555/tcp is published** (WebRTC, forwarded by the router). The go2rtc API
  (1984) and RTSP output (8554) are reachable on the Docker network only.
- The public viewer goes through NPM with a path filter, see `docs/network.md`.
- `vivosun-fetcher` is my own image, built by GitHub Actions in
  [iGridZ/vivosun-fetcher](https://github.com/iGridZ/vivosun-fetcher).
- Configs with camera credentials stay on the host and are not part of this repo.

## Stream layout (configs on the host)

`/docker/config/go2rtc/go2rtc.yaml`:

```yaml
streams:
  rtsp-cam:                 # main stream, credentials kept fresh by vivosun-fetcher
    - rtsp://<user>:<pass>@192.168.1.88:554/cam/realmonitor?channel=1&subtype=0
  rtsp-sub:                 # sub stream
    - rtsp://<user>:<pass>@192.168.1.88:554/h264/ch1/sub/av_stream
  growcam:                  # main, video only
    - rtsp://127.0.0.1:8554/rtsp-cam?video
  growcam_sub:              # sub, video only
    - rtsp://127.0.0.1:8554/rtsp-sub?video
```

## Deploy

Back up the config first:

```bash
sudo cp -a /docker/config/go2rtc  /docker/config/go2rtc.bak-$(date +%F)
cd ~/homelab/stacks/camera
cp .env.example .env && chmod 600 .env && nano .env   # first time only
docker rm -f vivosun-fetcher go2rtc
docker compose up -d --remove-orphans
docker compose logs -f vivosun-fetcher   # expect "OK - stream 'rtsp-cam' updated on http://go2rtc:1984"
```

Checks: `onlyplants` viewer plays, GrowView works.

CLI alternative: `./run.sh`
