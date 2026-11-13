#!/usr/bin/env bash
# inventory.sh — read-only snapshot of the homelab for documentation.
# It changes NOTHING on the system. Secrets in env vars / scripts are redacted.
#
# Usage:  sudo bash scripts/inventory.sh         (sudo is optional but gives more detail:
#                                                firewall, SSH config, process names on ports)
# Output: ~/homelab-inventory-<host>-<date>.txt  — skim it, then send it back.

set -uo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
OUT="${1:-$USER_HOME/homelab-inventory-$(hostname)-$(date +%Y%m%d-%H%M).txt}"
SELF="$(readlink -f "$0")"

# Anything whose key looks secret gets its value replaced; user:pass@ in URLs too.
redact() {
  sed -E \
    -e 's/([A-Za-z0-9_.-]*(PASS|PW|SECRET|TOKEN|KEY|AUTH|CRED|COOKIE|SESSION|SALT)[A-Za-z0-9_.-]*)([=:] ?)("[^"]*"|'"'"'[^'"'"']*'"'"'|[^ "'"'"',]+)/\1\3***REDACTED***/Ig' \
    -e 's/(--?[A-Za-z-]*(token|password|passwd|secret|key|auth)[A-Za-z-]*)( +)[^ -][^ ]*/\1\3***REDACTED***/Ig' \
    -e 's/eyJ[A-Za-z0-9_=.-]{20,}/***REDACTED-JWT***/g' \
    -e 's#://[^/:@ ]+:[^@ ]+@#://***:***@#g'
}

have() { command -v "$1" >/dev/null 2>&1; }
sec()  { printf '\n\n==================== %s ====================\n' "$*"; }
run()  { printf '\n$ %s\n' "$1"; timeout 90 bash -c "$1" 2>&1 | redact; }

{
  echo "Homelab inventory — $(date -Is) — run as $(id -un) (sudo user: $USER_NAME)"

  sec "SYSTEM"
  run "cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_ID)='"
  run "uname -r; uptime"
  run "lscpu | grep -E 'Model name|^CPU\(s\)|MHz|Virtualization'"
  run "free -h; swapon --show; echo swappiness=\$(cat /proc/sys/vm/swappiness)"
  have zramctl && run "zramctl"
  run "df -hT -x tmpfs -x devtmpfs -x overlay -x squashfs"
  run "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,ROTA"
  have sensors && run "sensors"
  run "ls -l /dev/dri 2>/dev/null || echo 'no /dev/dri'"
  have vainfo && run "vainfo --display drm --device /dev/dri/renderD128 2>&1 | grep -E 'Driver|VAProfile' | head -40"
  run "ps -eo pid,comm,%mem,%cpu,rss --sort=-rss | head -20"
  run "systemctl --failed --no-pager"
  run "systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{print \$1}'"

  sec "UPDATES"
  run "apt list --upgradable 2>/dev/null | tail -n +2 | wc -l"
  run "systemctl is-enabled unattended-upgrades; cat /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null"

  sec "NETWORK & SECURITY"
  run "ip -brief addr"
  run "ss -tulpn"
  [ "$(id -u)" -ne 0 ] && echo "!! NOT RUN AS ROOT — firewall/SSH/log sizes will be missing. Use: sudo bash $0"
  have ufw && run "systemctl is-active ufw; ufw status verbose"
  run "iptables -S DOCKER-USER 2>/dev/null || echo 'no DOCKER-USER chain or no root'"
  have sshd && run "sshd -T 2>/dev/null | grep -Ei '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|x11forwarding|allowusers|maxauthtries) '"
  have fail2ban-client && run "fail2ban-client status"
  run "cat /etc/docker/daemon.json 2>/dev/null || echo 'no /etc/docker/daemon.json'"

  sec "CRON"
  run "crontab -u $USER_NAME -l 2>/dev/null || echo 'no user crontab'"
  run "crontab -l 2>/dev/null || echo 'no root crontab'"
  run "ls -1 /etc/cron.d"

  if have docker; then
    sec "DOCKER OVERVIEW"
    run "docker version --format 'client {{.Client.Version}} / server {{.Server.Version}}'"
    run "docker compose version 2>/dev/null || echo 'compose plugin not installed'"
    run "docker info --format 'driver={{.Driver}} logging={{.LoggingDriver}} cgroup={{.CgroupVersion}} root={{.DockerRootDir}}'"
    run "docker system df"
    run "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
    run "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'"
    run "docker network ls"
    run "for n in \$(docker network ls -q); do docker network inspect -f '{{.Name}} ({{.Driver}}): {{range .Containers}}{{.Name}} {{end}}' \$n; done"
    run "docker volume ls"
    run "docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}'"

    sec "DOCKER CONTAINERS (detail)"
    TPL='
--- {{.Name}} ---
image:        {{.Config.Image}}
state:        {{.State.Status}}  restarts={{.RestartCount}}  health={{with index .State "Health"}}{{.Status}}{{else}}none{{end}}
restart:      {{.HostConfig.RestartPolicy.Name}}
network_mode: {{.HostConfig.NetworkMode}}
networks:     {{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}
ports:        {{range $p, $b := .HostConfig.PortBindings}}{{range $b}}{{.HostIp}}:{{.HostPort}}->{{end}}{{$p}}  {{end}}
devices:      {{range .HostConfig.Devices}}{{.PathOnHost}} {{end}}
privileged:   {{.HostConfig.Privileged}}   user: {{.Config.User}}   cap_add: {{.HostConfig.CapAdd}}
limits:       mem={{.HostConfig.Memory}} nanocpus={{.HostConfig.NanoCpus}} shm={{.HostConfig.ShmSize}}
log:          {{.HostConfig.LogConfig.Type}} {{.HostConfig.LogConfig.Config}}
cmd:          {{.Config.Cmd}}
mounts:{{range .Mounts}}
  {{.Type}} {{.Source}} -> {{.Destination}} ({{if .RW}}rw{{else}}ro{{end}}){{end}}
env:{{range .Config.Env}}
  {{.}}{{end}}'
    for c in $(docker ps -aq); do
      docker inspect --format "$TPL" "$c" 2>&1 | redact
      printf 'log size: '; du -h "$(docker inspect --format '{{.LogPath}}' "$c")" 2>/dev/null | cut -f1 || echo '?'
    done

    sec "PROBLEM CONTAINERS (last log lines)"
    for c in $(docker ps -a --filter status=restarting --filter status=exited -q) \
             $(docker ps --filter health=unhealthy -q); do
      printf '\n--- %s ---\n' "$(docker inspect -f '{{.Name}}' "$c")"
      docker logs --tail 15 "$c" 2>&1 | redact
    done
  else
    sec "DOCKER"; echo "docker not found"
  fi

  sec "CONFIG DIRECTORIES"
  for d in /docker /opt "$USER_HOME"; do
    [ -d "$d" ] && run "find '$d' -maxdepth 2 -type d -not -path '*/.*' | sort | head -80"
  done

  sec "RUN / COMPOSE SCRIPTS (redacted)"
  find /docker /opt "$USER_HOME" -maxdepth 3 -type f \
       \( -name '*.sh' -o -name 'compose*.y*ml' -o -name 'docker-compose*.y*ml' \) \
       -size -50k -not -path '*/.*' 2>/dev/null | sort | while read -r f; do
    [ "$(readlink -f "$f")" = "$SELF" ] && continue
    printf '\n----- %s -----\n' "$f"
    redact < "$f"
  done

  echo; echo "== done =="
} > "$OUT" 2>&1

chown "$USER_NAME": "$OUT" 2>/dev/null || true
echo "Inventory written to: $OUT"
echo "Please skim it before sending (secrets are redacted by key name, but double-check)."
