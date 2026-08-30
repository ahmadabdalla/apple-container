# Inventory and maintenance

Load this reference for storage audits, targeted removal, pruning, or snapshot
questions. Use the CLI as the source of truth; do not modify Apple container's
application data directly.

## Preserve state

Record whether services and the builder are running before starting anything:

```bash
container system status
container builder status
```

If services are down, `builder status` and inventory commands may fail over XPC.
Start services only when needed and stop them afterward if this task started
them. Parse the builder's `STATE`; do not rely on its command exit code alone.

## Inventory

```bash
container system version
container system df
container ls --all --format json
container image ls --format json
container network ls --format json
container volume ls --format json
container machine ls --format json
```

Use `container inspect`, `container image inspect`, `container network inspect`,
or `container volume inspect` before deleting an ambiguous target.

## Targeted cleanup

Prefer the narrowest command that matches the request:

```bash
container rm CONTAINER
container image rm IMAGE_OR_TAG
container volume rm VOLUME
container network rm NETWORK
container machine rm MACHINE
```

Removal is destructive. Resolve exact targets first and report what was removed
and whether it can be recreated or recovered.

## Pruning

Check disk usage before and after:

```bash
container system df
container prune
container image prune
container volume prune
container network prune
container system df
```

`container image prune` removes only dangling images. `container image prune -a`
removes every image not referenced by a container and can delete useful caches;
use `-a` only when the user has authorized that broader scope. Network prune
preserves default and system networks.

There is no single `container system prune` equivalent. Do not substitute raw
filesystem deletion.

## Snapshots

Directories below
`~/Library/Application Support/com.apple.container/snapshots` are materialized
filesystems backing images and containers. Their apparent directory size may
differ from the space reclaimed because the files can be sparse or shared.

Remove the owning image/container through the CLI, then use supported prune
commands. Never delete snapshot directories by digest: doing so can corrupt
retained images, BuildKit, or container state.
