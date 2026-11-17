# teamspeak

[TeamSpeak 6](https://teamspeak.com) voice server.

| | |
|---|---|
| Container | `teamspeak-server` |
| Access | `ts6.<domain>` (DNS only, not proxied): voice UDP 42069 → 9987, file transfer TCP 30033 |
| Data | Docker volume `teamspeak-data` (pre-existing, `external`) |
| Secrets | none in the stack (server admin token lives in the data volume) |

## Notes

- Both ports are forwarded by the router; TeamSpeak cannot go through NPM.
- ServerQuery ports are not published.
- The image runs as the unprivileged `teamspeak` user; all capabilities are dropped.
- TeamSpeak 6 server is still in beta: update by changing the tag here.

## Deploy

`docker compose up -d` also **starts** the server. To only create it while it is
meant to stay off, use `docker compose create`.

```bash
docker rm -f teamspeak-server
cd ~/homelab/stacks/teamspeak
docker compose up -d        # or: docker compose create
docker compose logs --tail 30
```

CLI alternative: `./run.sh`
