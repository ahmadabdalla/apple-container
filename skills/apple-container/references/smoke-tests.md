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
  sh -eu -c '
    printf "arch=%s\n" "$(uname -m)"
    printf "kernel=%s\n" "$(uname -r)"
    sed -n "1,3p" /etc/os-release
  '
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

Use the bundled verifier to check the directory-source and read-only bind
contracts with an image that is already local and contains `sh`:

```bash
scripts/verify-readonly-bind.sh docker.io/library/alpine:latest
```

The verifier uses a private synthetic fixture rather than the workspace. It
requires a regular-file bind to be rejected, confirms that a non-root guest can
read a staged file but cannot modify it through a read-only directory bind, and
checks that the host SHA-256 digest is unchanged. Cleanup targets only the
fixture created by that run.

## Build check

```bash
build_context=$(mktemp -d)

cat > "$build_context/Dockerfile" <<'EOF'
FROM alpine:latest
CMD echo -n "Architecture is " && uname -m
EOF

container build -t uname-test "$build_context"
container run --rm uname-test
```

Expected:

```text
Architecture is aarch64
```

Clean up the temporary directory when finished:

```bash
rm "$build_context/Dockerfile"
rmdir "$build_context"
```
