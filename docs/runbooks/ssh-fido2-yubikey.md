# Runbook: SSH with FIDO2 keys (YubiKey)

Implements [ADR 0003](../decisions/0003-ssh-fido2-yubikey.md).
Client: Windows (PowerShell). Server: the t630 (`rock`).

## 1. Client prerequisites

```powershell
ssh -V            # needs OpenSSH 8.9 or newer
where.exe ssh     # the newest ssh.exe must be listed first
```

If the version is older (Windows 10 ships 8.1):

```powershell
winget search openssh
winget install Microsoft.OpenSSH.Preview
```

In Yubico Authenticator, for **each** YubiKey: *Passkeys / FIDO2 → Set PIN*, and note
the firmware version (≥ 5.2.3 → `ed25519-sk`, older → `ecdsa-sk`).

> Use **PowerShell**, not cmd — cmd does not expand `$HOME`.

## 2. Create one key per YubiKey

```powershell
mkdir $HOME\.ssh -Force
# YubiKey 1 plugged in
ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:rock -C "yubikey-1" -f $HOME\.ssh\id_yk1
# YubiKey 2 plugged in
ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:rock -C "yubikey-2" -f $HOME\.ssh\id_yk2
```

## 3. Install the public keys on the server

```powershell
type $HOME\.ssh\id_yk1.pub, $HOME\.ssh\id_yk2.pub | ssh rock@192.168.1.245 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## 4. Client config

`$HOME\.ssh\config`:

```
Host rock
    HostName 192.168.1.245
    User rock
    IdentityFile ~/.ssh/id_yk1
    IdentityFile ~/.ssh/id_yk2
```

Test **each** key separately — both must ask for PIN + touch, not for a password:

```powershell
ssh -i $HOME\.ssh\id_yk1 rock@192.168.1.245
ssh -i $HOME\.ssh\id_yk2 rock@192.168.1.245
```

## 5. Harden sshd

Only after both keys work. **Keep the current session open** as a fallback.

```bash
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
# Only FIDO2 hardware keys, no passwords, no root
PubkeyAcceptedAlgorithms sk-ssh-ed25519@openssh.com,sk-ecdsa-sha2-nistp256@openssh.com
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
MaxAuthTries 3
AllowUsers rock
X11Forwarding no
EOF
sudo sshd -t && sudo systemctl restart ssh
sudo sshd -T | grep -Ei '^(pubkeyacceptedalgorithms|passwordauthentication|permitrootlogin|maxauthtries|allowusers)'
```

The `10-` prefix matters: sshd uses the **first** value it reads, and Ubuntu may ship
`50-cloud-init.conf` with `PasswordAuthentication yes`.

## 6. Verify

From a second terminal:

```powershell
ssh rock                 # YubiKey plugged in → PIN + touch → logged in
```

Without a YubiKey the result must be `Permission denied (publickey)` with no password prompt.

## Rollback

From the still-open session (or the local console):

```bash
sudo rm /etc/ssh/sshd_config.d/10-hardening.conf && sudo systemctl restart ssh
```

## New client PC

Keys were created with `resident`, so they can be loaded from the YubiKey:

```powershell
cd $HOME\.ssh
ssh-keygen -K        # writes id_*_sk_rk files for the plugged-in YubiKey
```
