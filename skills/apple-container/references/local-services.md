# Apple container local services

Use these commands when the user wants to run a long-lived local service with
Apple `container`.

## Local-only service pattern

Use `127.0.0.1:HOST_PORT:CONTAINER_PORT` to expose the service only to the Mac.

```bash
NAME=my-local-service
HOST_PORT=18080
CONTAINER_PORT=8000

container rm "$NAME" >/dev/null 2>&1 || true

container run --detach \
  --name "$NAME" \
  --publish 127.0.0.1:${HOST_PORT}:${CONTAINER_PORT} \
  --env KEY=value \
  --volume "$PWD:/workspace:ro" \
  IMAGE \
  COMMAND
```

Use `:ro` bind mounts when a service only needs to inspect project files.

Verify:

```bash
container ls
lsof -nP -iTCP:${HOST_PORT} -sTCP:LISTEN
curl -fsS http://127.0.0.1:${HOST_PORT}/
container logs "$NAME"
```

Clean up:

```bash
container stop "$NAME"
container rm "$NAME"
```

## Python HTTP service test

```bash
container run --detach \
  --name apple-container-web-test \
  --publish 127.0.0.1:18080:8000 \
  docker.io/library/python:3.12-alpine \
  sh -c 'mkdir -p /www && echo apple-container-ok > /www/index.html && cd /www && exec python -m http.server 8000 --bind 0.0.0.0'

curl -fsS http://127.0.0.1:18080/

container stop apple-container-web-test
container rm apple-container-web-test
```

Expected:

```text
apple-container-ok
```

## npm-backed service pattern

Use a Node base image when the service is distributed as an npm package and does
not need a custom image yet.

```bash
container run --detach \
  --name node-service-test \
  --publish 127.0.0.1:3001:3001 \
  docker.io/library/node:22-alpine \
  sh -c 'exec npx -y PACKAGE_NAME ARGS'
```

For durable use, prefer a `Dockerfile` or `Containerfile` that installs the npm
package instead of downloading it on every run.

## Diagnostics for services

```bash
container ls
container ls --all
container logs NAME
container inspect NAME
container exec NAME sh
lsof -nP -iTCP:HOST_PORT -sTCP:LISTEN
```

A listening host port only proves forwarding is active. The application may
still require a specific path, method, protocol, or headers.
