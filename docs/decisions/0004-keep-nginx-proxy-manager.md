# 0004 – Keep Nginx Proxy Manager as reverse proxy

- **Status:** Accepted
- **Date:** 2026-11-13

## Context

Nginx Proxy Manager (NPM) stores its proxy hosts, certificates and access lists in
an internal database edited through a web UI. That configuration therefore cannot
be versioned, reviewed or validated in CI. Alternatives that keep proxy rules as
code are Traefik (Docker labels) and Caddy (Caddyfile).

## Decision

Keep NPM. It works, I know it well, and a proxy migration would add risk to every
public service at the same time as the Compose migration.

To compensate for the missing config-as-code:

- Proxy hosts are documented in [network.md](../network.md) (hostname → target,
  access class)
- NPM's data directory is part of the backup set
- Public apps must have their own authentication; NPM only terminates TLS

## Consequences

- ✅ No migration risk, familiar tooling
- ➖ Proxy changes are not reviewed through pull requests and can drift from the docs
- ➖ Revisit if the number of proxy hosts grows or if CI/CD for the proxy layer
  becomes a goal (Traefik would be the candidate)
