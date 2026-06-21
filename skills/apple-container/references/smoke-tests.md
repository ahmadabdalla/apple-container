# Apple container smoke tests

Use these commands when the user wants to verify that Apple `container` works
end to end.

## Detect and start

```bash
uname -m
sw_vers -productVersion
command -v container || echo "container not found"
container --version
container system status
container system start
container system status
```

Expected basics:

```text
arm64
container CLI version ...
status running
```

## Run Alpine

```bash
container run --rm docker.io/library/alpine:latest \
  sh -c 'echo arch=$(uname -m); echo kernel=$(uname -r); sed -n "1,3p" /etc/os-release'
```

Expected architecture on Apple Silicon:

```text
arch=aarch64
```

## List local state

```bash
container image ls
container ls
container network ls
container volume ls
```

Important: use `container image ls`, not `container images ls`.

## Bind mount check

```bash
container run --rm \
  --volume "$PWD:/work" \
  docker.io/library/alpine:latest \
  sh -c 'pwd; ls -la /work | sed -n "1,20p"'
```

Expected result: files from the current host directory appear under `/work`.

## Build check

```bash
mkdir -p /tmp/apple-container-build-test
cd /tmp/apple-container-build-test

cat > Dockerfile <<'EOF'
FROM alpine:latest
CMD echo -n "Architecture is " && uname -m
EOF

container build -t uname-test .
container run --rm uname-test
```

Expected:

```text
Architecture is aarch64
```

Clean up the temporary directory when finished:

```bash
rm -rf /tmp/apple-container-build-test
```
