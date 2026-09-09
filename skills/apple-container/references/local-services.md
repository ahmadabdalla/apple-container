# Apple container local services

Use these commands when the user wants to run a long-lived local service with
Apple `container`.

## Local-only service pattern

Use `127.0.0.1:HOST_PORT:CONTAINER_PORT` to expose the service only to the Mac.

```bash
service_name=my-local-service
host_port=18080
container_port=8000

if container inspect "$service_name" >/dev/null 2>&1; then
  container rm "$service_name"
fi

container run --detach \
  --name "$service_name" \
  --publish "127.0.0.1:${host_port}:${container_port}" \
  --env KEY=value \
  --volume "$PWD:/workspace:ro" \
  IMAGE \
  COMMAND
```

Use `:ro` bind mounts when a service only needs to inspect project files.

Verify:

```bash
container ls
lsof -nP -iTCP:"$host_port" -sTCP:LISTEN
curl -fsS \
  --retry 5 --retry-all-errors --retry-delay 1 \
  --max-time 2 \
  "http://127.0.0.1:${host_port}/"
container logs "$service_name"
```

Clean up:

```bash
container stop "$service_name"
container rm "$service_name"
```

## Python HTTP service test

```bash
container run --detach \
  --name apple-container-web-test \
  --publish 127.0.0.1:18080:8000 \
  docker.io/library/python:3.12-alpine \
  sh -eu -c '
    mkdir -p /www
    printf "%s\n" apple-container-ok > /www/index.html
    exec python -m http.server 8000 --bind 0.0.0.0 --directory /www
  '

curl -fsS \
  --retry 5 --retry-all-errors --retry-delay 1 \
  --max-time 2 \
  http://127.0.0.1:18080/

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
  sh -eu -c 'exec npx -y PACKAGE_NAME ARGS'
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
