---
name: podman-in-workspace
description: Use when running container workloads (podman, docker, traefik, whoami, docker-compose) inside this workspace's opencode-workspace container. Documents the required --privileged flag, cgroup remount, ulimit workarounds, and --network host for the userns sandbox.
---

# Podman in the opencode-workspace container

This workspace is a user-namespace sandbox (root maps to host uid 1001).
Nested container tooling is only usable with specific workarounds. This skill
documents the exact commands that work.

## Facts about this environment

- Host docker daemon works for running containers: `docker run ghcr.io/jyasuu/opencode-workspace:main ...`
- The `ghcr.io/jyasuu/opencode-workspace:main` image is bare Ubuntu 22.04:
  no podman, no docker, no docker-compose inside. Default `CMD` is `/bin/bash`.
- Inside the workspace container:
  - `iptables`/`nat` are unsupported (`TABLE_ADD failed (Operation not supported)`),
    so podman's default CNI bridge network **cannot** be used.
  - Hard resource limits are capped (nofile=65535, nproc=63995); podman's
    default ulimits exceed them, so crun aborts with
    `setrlimit RLIMIT_NOFILE/NPROC: Operation not permitted`.
  - `/sys/fs/cgroup` mounts are read-only until remounted.

## Minimal setup inside the workspace container

Start the container privileged and keep it alive:

```bash
docker run -d --name ws --privileged ghcr.io/jyasuu/opencode-workspace:main sleep infinity
```

Install podman and curl:

```bash
docker exec ws bash -c 'apt-get update -qq && apt-get install -y -qq podman curl'
```

Make cgroups writable (userns sandbox needs a fresh hierarchy):

```bash
docker exec ws bash -c '
umount /sys/fs/cgroup 2>/dev/null
mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup
for c in blkio cpu cpuacct cpu,cpuacct cpuset devices freezer hugetlb memory net_cls net_prio perf_event pids systemd; do
  mkdir -p /sys/fs/cgroup/$c
  mount -t cgroup -o $c cgroup /sys/fs/cgroup/$c 2>/dev/null
done
'
```

**Where commands run:** the `docker run`/`docker exec` blocks above run on the
host. Every podman, socket, and curl command from here on runs **inside** the
`ws` container — wrap them in `docker exec ws bash -c '...'`.

## The two podman rules that make containers actually run

1. **Always use `--network host`** — the CNI bridge needs iptables, which the
   sandbox blocks.
2. **Always pass matching ulimits** — crun 0.17 cannot raise them above the
   sandbox hard limits:

```bash
podman run -d --name <name> --network host \
  --ulimit nofile=1024:1024 --ulimit nproc=4096:4096 \
  <image>
```

Known pitfalls:

- Running two `podman run` commands too fast can leave stale containers that
  block name reuse. `podman rm -f -a` first.
- `containers.conf` `ulimit` keys are ignored by podman 3.4.4; flags are required.
- Without the ulimit flags, `--network host` containers fail with
  `setrlimit RLIMIT_NOFILE: Operation not permitted: OCI permission denied`.

## Exposing podman to tools that need a Docker API socket

Traefik's Docker provider needs a socket. Start podman's API service and mount
it into the tool container:

```bash
mkdir -p /run/podman
nohup podman system service --time=0 unix:///run/podman/podman.sock >/tmp/podman-svc.log 2>&1 &
sleep 3
ls -la /run/podman/podman.sock   # must exist before proceeding
```

The service dies with the `ws` container; restart it if you rebuilt it.

## Reference example: traefik + whoami

whoami owns host port 80; traefik listens on web `:8080` and dashboard `:9090`.
All commands below run inside the `ws` container:

```bash
docker exec ws bash -c '
podman run -d --name whoami --network host --ulimit nofile=1024:1024 --ulimit nproc=4096:4096 \
  -l traefik.enable=true -l traefik.http.routers.whoami.rule="Host(\`whoami.localhost\`)" \
  -l traefik.http.services.whoami.loadbalancer.server.port=80 docker.io/traefik/whoami

podman run -d --name traefik --network host --ulimit nofile=1024:1024 --ulimit nproc=4096:4096 \
  -v /run/podman/podman.sock:/run/docker.sock:ro \
  docker.io/library/traefik:v3.2 --api.insecure=true --api.dashboard=true \
  --entryPoints.web.address=:8080 --entryPoints.traefik.address=:9090 \
  --providers.docker=true --providers.docker.endpoint=unix:///run/docker.sock

sleep 10
podman ps
'
```

About the `Host(\`whoami.localhost\`)` label: `podman run -d` returns before the
containers are listening, so wait (e.g. `sleep 10`) and confirm `podman ps`
shows both before curling. The backslashes are load-bearing: bash turns the
escaped backticks into literal backtick characters, which is the quote form
traefik's rule grammar requires. Do not unescape them — unquoted backticks
trigger shell command substitution and routing silently stops matching
(`Host()` matches nothing, no error is raised).

Verify (inside the `ws` container):

```bash
curl -H "Host: whoami.localhost" localhost:8080   # whoami response + X-Forwarded-* headers
curl localhost:9090/api/overview                  # traefik dashboard API
```

## Quick reference

| Task | Command |
| --- | --- |
| Run a container | `podman run -d --network host --ulimit nofile=1024:1024 --ulimit nproc=4096:4096 <image>` |
| Use a Docker-API tool | `podman system service --time=0 unix:///run/podman/podman.sock` |
| Clean stale containers | `podman rm -f -a` |
| Diagnose run failures | `podman ps -a`, `podman logs <name>`, `podman inspect <name>` |
