# 0003 – SSH with FIDO2 hardware keys only

- **Status:** Accepted (implemented 2026-11-13)
- **Date:** 2026-11-13

## Context

SSH accepted passwords and allowed root login with a key. Port 22 is not forwarded,
so exposure is limited to the LAN and VPN — but a password that can be phished or
reused is the weakest link once anything inside the network is compromised.

I own two YubiKeys, and OpenSSH (≥ 8.2) supports FIDO2-backed keys
(`ed25519-sk`). The private key never leaves the YubiKey; the file on the client
is only a handle.

## Decision

- One `ed25519-sk` key per YubiKey, created with `-O resident -O verify-required`
  (stored on the key, PIN + touch on every login)
- Both public keys in `authorized_keys`; the second YubiKey is the spare
- `sshd` drop-in config: only `sk-*` key types accepted, no passwords, no root,
  `AllowUsers rock`, `MaxAuthTries 3`

Procedure: [runbooks/ssh-fido2-yubikey.md](../runbooks/ssh-fido2-yubikey.md)

## Consequences

- ✅ Phishing-resistant: a stolen laptop or leaked file is not enough to log in
- ✅ `resident` keys can be loaded onto any new client with `ssh-keygen -K`
- ➖ Clients need OpenSSH ≥ 8.9 (Windows: install the current Microsoft OpenSSH build)
- ➖ Losing both YubiKeys means local console access is needed to recover
  (the hardening only applies to SSH, local login is unaffected)
