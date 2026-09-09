# Current feature surface

Load this reference for Apple container features beyond ordinary run/build/list
workflows. Check `container --version` and local `--help` because the project
changes quickly and some commands depend on the macOS version.

## Command groups

| Area | High-value commands |
| --- | --- |
| Containers | `create`, `start`, `stop`, `kill`, `exec`, `export`, `copy`, `prune` |
| Images | `pull`, `push`, `save`, `load`, `tag`, `inspect`, `rm`, `prune` |
| Builder | `start`, `status`, `stop`, `rm` |
| Networks | `create`, `inspect`, `rm`, `prune` |
| Volumes | `create`, `inspect`, `rm`, `prune` |
| Registries | `login`, `logout`, `list` |
| Machines | `create`, `run`, `set`, `set-default`, `logs`, `stop`, `rm` |
| System | `version`, `status`, `df`, `logs`, `dns`, `kernel`, `property` |
| Kubernetes | `k8s create`, `start`, `ls`, `load-image`, `write-config`, `rm` |

Command groups are singular. Confirm exact flags with
`container <group> <command> --help` instead of inferring Docker syntax.

## Container machines

Use a container machine when the user wants a persistent Linux environment,
init-system services, or a Linux shell with their macOS username and home
directory mapped in. Use ordinary `container run` for an isolated application.

```bash
container machine create alpine:latest --name dev
container machine run -n dev
container machine set -n dev cpus=4 memory=8G home-mount=ro
container machine stop dev
container machine rm dev
```

Configuration changes take effect after restart. `home-mount` accepts `rw`,
`ro`, or `none`. Nested virtualization requires compatible Apple silicon and a
guest kernel built with KVM support; validate it with local help and Apple's
[container machine guide](https://github.com/apple/container/blob/1.3.1/docs/container-machine.md).

## Experimental Kubernetes plugin

Current releases include an experimental plugin for local single-node clusters.
Verify that services are running and that `container k8s --help` is available
before using it.

```bash
container k8s create --name dev
container k8s ls
container k8s load-image --name dev IMAGE
container k8s write-config --name dev
container k8s rm --name dev
```

Creation can pull a node image, change `~/.kube/config`, and consume significant
resources. Treat those as explicit side effects. Do not present this
experimental plugin as a replacement for mature Kubernetes or team-standard
cluster tooling.

## Advanced run and build features

Use `container run --help` when the task needs custom init images or kernels,
Unix socket publication, SSH-agent forwarding, `/dev/shm` sizing, masked or
read-only paths, Rosetta, or nested virtualization.

Use `container build --help` for build arguments, secrets, SSH forwarding,
targets, multiple platforms, cache control, pulls, and OCI/tar/local outputs.
Build secrets should use `--secret`; do not bake credentials into image layers
or pass them as ordinary build arguments.

## Docker gaps

There is no Compose or Docker socket/API compatibility. There are also no direct
equivalents for common Docker operations such as `restart`, `commit`, `attach`,
`pause`, `rename`, or restart policies. Confirm the current surface rather than
inventing a plausible command.
