# Apple container troubleshooting

Use these commands when Apple `container` fails to install, start, run, publish
ports, or keep a container alive.

## Command discovery

```bash
container --help
container run --help
container image --help
container system --help
container builder --help
container network --help
container volume --help
container registry --help
container machine --help
```

Use `container image ls`, not `container images ls`.

An unknown subcommand can fall through to the plugin loader and report that
plugins or services are unavailable. Check spelling and the relevant group help
before restarting services. Trust the service hint only when
`container system status` also reports the service down.

## Service and install checks

```bash
command -v container
container --version
container system status
container system version
container system logs | tail -n 100
brew info --formula container
ls -la "$HOME/Library/Application Support/com.apple.container/"
```

Start or restart the service:

```bash
container system stop
container system start
container system status
```

Do not restart automatically for a read-only question when offline inspection
is enough. If the task starts services temporarily, restore their prior state.

## Container exited immediately

```bash
container ls --all
container logs NAME
container inspect NAME
```

Common causes:

- The command finished successfully and the container exited.
- The process printed an error and exited.
- The image lacks the command or applet being invoked.
- The service binds to `127.0.0.1` inside the container instead of `0.0.0.0`.

## Port publishing fails

Check the host port:

```bash
lsof -nP -iTCP:HOST_PORT -sTCP:LISTEN
```

Check container state and logs:

```bash
container ls
container logs NAME
container inspect NAME
```

Check listening ports inside the container:

```bash
container exec NAME sh -eu -c '
  if command -v netstat >/dev/null; then
    exec netstat -lnt
  fi
  if command -v ss >/dev/null; then
    exec ss -lnt
  fi
  echo "neither netstat nor ss is installed" >&2
  exit 1
'
```

Use local-only publishing unless LAN access is required:

```bash
container run --publish 127.0.0.1:HOST_PORT:CONTAINER_PORT IMAGE CMD
```

## Stale container name

If a rerun fails because the name already exists:

```bash
container rm NAME
```

For a running container:

```bash
container stop NAME
container rm NAME
```
