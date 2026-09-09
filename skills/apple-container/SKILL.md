---
name: apple-container
description: >-
  Use for Apple's container CLI on macOS: installation and service checks, OCI
  containers and images, builds, ports, mounts, networks, volumes, container
  machines, local Kubernetes, cleanup, troubleshooting, security-sensitive
  runs, or deciding whether Apple container fits instead of Docker tooling.
license: MIT
metadata:
  author: ahmadabdalla
  version: "0.3.3"
---

# Apple `container`

Use a command-first approach. Keep answers short, prefer copyable commands, and
load only the reference needed for the task. Run `container <group> --help`
before relying on a Docker-shaped command or a version-sensitive option.

Treat the gotchas, fast paths, and routed reference flows as distilled
operational learnings. Use the matching flow before exploratory probing so
agents do not repeat discovery or create avoidable back-and-forth. Re-check
local help or state only for version-sensitive details, genuine uncertainty, or
observed behavior that conflicts with the documented flow.

Use the installed CLI for ordinary and offline work; target the latest stable
when installing or upgrading. Examples were last verified on Apple container
1.3.1, Apple Silicon macOS 26+. Commands vary by release and macOS version.

## Fit and boundaries

Apple `container` is well suited to OCI images, isolated local services, builds,
Linux sandboxes, and persistent Linux environments through `container machine`.
Current releases also include an experimental single-node `container k8s`
plugin.

Keep Docker or the team's standard tooling when the workflow requires Compose,
the Docker API/socket, Dev Containers, Testcontainers, mature Kubernetes
integration, or exact Docker-compatible behavior. Do not describe the
experimental Kubernetes plugin as equivalent to a production-grade stack.

## Operating rules

- Command groups are singular: `container image ls`, not `container images ls`.
- Check `container system status`; start services only when the requested command
  requires them. Restore the original service and builder state after temporary
  diagnostics or security-sensitive work.
- A misspelled command can fall through to the plugin loader and misleadingly
  report that services are unavailable. Confirm the command with `--help` before
  restarting anything.
- Use `container ls --all`; detached containers can start and exit immediately.
- Use `--format json` for parseable `ls`, `stats`, and `system df` output;
  `inspect` commands already emit JSON. `container stats` streams unless
  `--no-stream` is supplied.
- Builds use a builder VM. Check the reported state from `container builder
  status`; a zero exit code does not mean the state is running.
- For local-only ports, publish `127.0.0.1:HOST:CONTAINER` and bind the service
  inside the container to `0.0.0.0`.
- Bind mounts accept host directories, not regular-file sources, in confirmed
  releases 1.3.1 and 1.4.1. They are writable by default; stage individual
  inputs in a private directory, mount it `readonly`, and expose only dedicated
  writable output paths for untrusted workloads.
- Use CLI remove/prune commands for cleanup. Never delete files directly below
  `~/Library/Application Support/com.apple.container`; snapshots back retained
  images and containers.
- For non-native images, use `--platform`/`--arch`, `--rosetta` where supported,
  or `CONTAINER_DEFAULT_PLATFORM` deliberately.

## Fast path

```bash
uname -m
sw_vers -productVersion
command -v container || echo "container not found"
container --version
container system status
```

Install or start when needed:

```bash
brew info --formula container
brew install container
container system start
```

Core commands:

| Goal | Command |
| --- | --- |
| Run and remove | `container run --rm IMAGE CMD` |
| Run detached | `container run -d --name NAME IMAGE CMD` |
| Local port | `container run -p 127.0.0.1:18080:8000 IMAGE CMD` |
| Read-only bind | `container run -v "$PWD:/work:ro" IMAGE CMD` |
| Build | `container build -t NAME .` |
| Containers | `container ls --all` |
| Images | `container image ls` |
| Inspect/log/exec | `container inspect NAME`; `container logs NAME`; `container exec NAME CMD` |
| Networks/volumes | `container network ls`; `container volume ls` |
| Disk usage | `container system df` |
| Persistent Linux | `container machine create IMAGE --name NAME` |
| Help | `container <command-or-group> --help` |

For basic localhost service experiments and simple OCI workflows, Apple
`container` may be enough. Prefer manual `container system start` while
evaluating; use `brew services start container` only when the user explicitly
wants it running at login.

## Load references only when needed

| Need | Reference |
| --- | --- |
| Install, smoke, bind mount, or build verification | [references/smoke-tests.md](references/smoke-tests.md) |
| Long-running localhost or npm-backed services | [references/local-services.md](references/local-services.md) |
| Failures, command discovery, exits, or port issues | [references/troubleshooting.md](references/troubleshooting.md) |
| Inventory, image removal, pruning, snapshots, or disk recovery | [references/maintenance.md](references/maintenance.md) |
| Machines, Kubernetes, registries, or newer run/build features | [references/current-features.md](references/current-features.md) |
| Untrusted inputs, offline or constrained egress, or hardening | [references/security-sensitive-runs.md](references/security-sensitive-runs.md) |

## Authoritative sources

- [Last-verified command reference (1.3.1)](https://github.com/apple/container/blob/1.3.1/docs/command-reference.md)
- [Apple container releases](https://github.com/apple/container/releases)
- [Apple Containerization framework](https://github.com/apple/containerization)
- [Homebrew formula](https://formulae.brew.sh/formula/container)
