# Stacks

One folder per service (or group of services that belong together). Each stack is
deployable on its own.

```
stacks/<name>/
├── compose.yaml     # source of truth
├── run.sh           # same configuration as plain docker CLI commands
├── .env.example     # every variable the stack needs, with placeholder values
└── README.md        # what it is, how it is reached, anything non-obvious
```

The real `.env` lives next to `compose.yaml` **on the host only** and is ignored by git.

## Conventions

- **Pinned image tags** (`jellyfin/jellyfin:10.11.0`), never `:latest`
- **No published ports** for services that are only reached through Nginx Proxy
  Manager — they join the external `proxy`/`media` network instead
- Published ports that remain are documented in [docs/network.md](../docs/network.md)
- `restart: unless-stopped`, a healthcheck where the image supports one
- `security_opt: [no-new-privileges:true]`; drop capabilities where the app allows it;
  never `privileged: true` without a written reason
- Log rotation: `json-file` with `max-size` / `max-file` (also set globally in
  `/etc/docker/daemon.json`)
- `TZ=Europe/Berlin` everywhere
- `compose.yaml` and `run.sh` change together in the same commit

Deploy a single stack on the host:

```bash
cd stacks/<name>
cp .env.example .env   # first time only, then fill in real values
docker compose up -d
```
