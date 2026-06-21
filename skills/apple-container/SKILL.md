---
name: apple-container
description: >-
  Use this skill when working with Apple's container CLI on macOS: checking
  installation, starting the service, running OCI containers, publishing local
  ports, bind mounting files, building images, troubleshooting local container
  failures, or deciding whether Apple container is enough versus Docker Desktop
  for simple local workflows.
license: MIT
compatibility: >-
  Requires Apple Silicon macOS. Commands assume Apple container CLI 1.0+,
  optional Homebrew for install, curl/lsof for checks, and internet access for
  pulling OCI images.
metadata:
  author: ahmadabdalla
  version: "0.2.0"
---

# Apple `container` command guide

Act as a command-first decision framework for Apple's `container` CLI. Keep
answers short, prefer copyable commands, and load reference files only when the
task needs more detail.

## Use this skill for

- Checking whether Apple `container` is installed and running.
- Installing or starting the local container service.
- Running simple OCI containers and local Linux sandboxes.
- Publishing local service ports and bind mounting host files.
- Building small images with `container build`.
- Troubleshooting Apple `container` command, service, image, network, or port
  publishing issues.
- Comparing Apple `container` with Docker Desktop for simple local workflows.

## Boundaries

Apple `container` is useful for basic OCI workflows. Do not present it as a full
Docker Desktop replacement when the user needs Docker Compose, Docker socket
compatibility, Dev Containers, Testcontainers, Kubernetes integration, or
team-standard Docker tooling.

## Gotchas

- Use `container image ls`, not `container images ls`.
- Start the service with `container system start` before `run`, `build`, or
  `push`.
- First run may fetch the kernel and init image before the container starts.
- Use `127.0.0.1:HOST_PORT:CONTAINER_PORT` for local-only services.
- For local services, bind the app inside the container to `0.0.0.0`, then
  publish on macOS as `127.0.0.1:HOST_PORT:CONTAINER_PORT`.
- A listening host port proves forwarding exists, not that the application path
  or protocol is valid.
- A detached container can appear to start successfully and then exit
  immediately. If a port probe fails, check logs and inspect.
- Prefer manual `container system start` while evaluating. Use
  `brew services start container` only after the user wants it running at login.

## Fast checks

```bash
uname -m
sw_vers -productVersion
command -v container || echo "container not found"
container --version
container system status
```

Expected basics:

```text
arm64
container CLI version ...
status running
```

Install with Homebrew if missing:

```bash
brew info --formula container
brew install container
container system start
```

Start, status, and stop:

```bash
container system start
container system status
container system stop
```

## Command map

| Goal            | Command                                         |
| --------------- | ----------------------------------------------- |
| Run and remove  | `container run --rm IMAGE CMD`                  |
| Run detached    | `container run --detach --name NAME IMAGE CMD`  |
| Publish port    | `container run --publish 18080:8000 IMAGE CMD`  |
| Local-only port | `container run --publish 127.0.0.1:18080:8000`  |
| Bind mount      | `container run --volume "$PWD:/work" IMAGE CMD` |
| Build image     | `container build -t NAME .`                     |
| List containers | `container ls`                                  |
| List all        | `container ls --all`                            |
| List images     | `container image ls`                            |
| Exec            | `container exec NAME CMD`                       |
| Logs            | `container logs NAME`                           |
| Inspect         | `container inspect NAME`                        |
| Stop            | `container stop NAME`                           |
| Remove          | `container rm NAME`                             |
| Remove stale    | See snippet below                               |
| Copy files      | `container cp SRC DEST`                         |
| List networks   | `container network ls`                          |
| List volumes    | `container volume ls`                           |
| System status   | `container system status`                       |
| System logs     | `container system logs`                         |

Stale remove snippet:

```bash
container rm NAME >/dev/null 2>&1 || true
```

## Default workflows

Run a tiny Linux container:

```bash
container run --rm docker.io/library/alpine:latest \
  sh -c 'echo arch=$(uname -m); echo kernel=$(uname -r); sed -n "1,3p" /etc/os-release'
```

Bind mount the current directory:

```bash
container run --rm \
  --volume "$PWD:/work" \
  docker.io/library/alpine:latest \
  sh -c 'pwd; ls -la /work | sed -n "1,20p"'
```

Run a local HTTP service:

```bash
container run --detach \
  --name my-local-service \
  --publish 127.0.0.1:18080:8000 \
  IMAGE \
  COMMAND
```

Verify a local service:

```bash
lsof -nP -iTCP:18080 -sTCP:LISTEN
curl -fsS http://127.0.0.1:18080/
container logs my-local-service
```

Clean up:

```bash
container stop my-local-service
container rm my-local-service
```

## Load references when needed

| Need                                                                 | Load                                                           |
| -------------------------------------------------------------------- | -------------------------------------------------------------- |
| Full install, smoke, bind mount, and build checks                    | [references/smoke-tests.md](references/smoke-tests.md)         |
| Long-running service, local port, or npm-backed service patterns     | [references/local-services.md](references/local-services.md)   |
| Failures, logs, exited containers, port issues, or command discovery | [references/troubleshooting.md](references/troubleshooting.md) |

## Recommendation language

For localhost service experiments, simple local sandboxes, and basic OCI
workflows, Apple `container` may be enough.

Keep Docker available when the workflow depends on Docker Compose, Docker
API/socket compatibility, Dev Containers, Testcontainers, Kubernetes
integration, or team-standard Docker tooling.

## References

| Topic                            | Reference                                        |
| -------------------------------- | ------------------------------------------------ |
| Apple `container` CLI            | https://github.com/apple/container               |
| Apple Containerization framework | https://github.com/apple/containerization        |
| Apple `container` API docs       | https://apple.github.io/container/documentation/ |
| Homebrew formula                 | https://formulae.brew.sh/formula/container       |
