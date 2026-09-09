# Security-sensitive runs

Load this reference when executing untrusted code or files, using third-party
images, or deliberately hardening a local workflow. Apple gives each container
the isolation of a lightweight VM, but host bind mounts and exported output
remain trust boundaries.

## Separate preparation from execution

- Fetch packages and build a minimal, reviewed image during an intentional
  network-enabled preparation phase. Keep ordinary untrusted runs offline.
- Keep tools and dependencies inside the image instead of installing them on
  macOS. Record the image tag plus its observed ID or digest and retain a package
  inventory when reproducibility or auditability matters.
- A pinned base digest improves repeatability but does not receive fixes by
  itself. Rebuild intentionally, apply updates, and check the resulting image
  for known vulnerabilities and unnecessary packages.

## Minimize the host surface

- Copy each input into a private, run-specific staging directory. Mount only
  the exact input and required tools as read-only; never expose broad paths such
  as the workspace root, the user's home directory, credentials, or sockets.
  A read-only credential mount prevents modification, not reading or
  exfiltration.
- Expose one dedicated, run-specific output directory as writable. Run as a
  non-root UID/GID and probe that exact output path before the real workload.
  VirtioFS ownership translation can vary, so do not assume every arbitrary UID
  can write and do not solve permission failures with world-writable host paths.
- Use a read-only root filesystem and a size-bounded tmpfs for required scratch
  space. Treat everything written by the workload as untrusted.

A compact baseline for macOS 26 and a current Apple `container` release is:

```bash
container run --rm \
  --network none --no-dns \
  --read-only --tmpfs /tmp:size=128M,mode=1777 \
  --user 10001:10001 --cap-drop ALL \
  --cpus 2 --memory 3G --ulimit nofile=1024:1024 \
  --mount type=bind,source=/absolute/staged-input,target=/input,readonly \
  --mount type=bind,source=/absolute/tools,target=/tools,readonly \
  --mount type=bind,source=/absolute/run-output,target=/output \
  IMAGE_TAG COMMAND
```

Adjust limits and add back only capabilities the application demonstrably
needs. `--no-dns` alone is not network isolation because raw IP traffic remains
possible. On macOS 15, `--network none` is unavailable; do not describe a
DNS-only fallback as offline.

Verify the network boundary with a prepared Alpine 3.24 image. Every negative
probe must fail; any unexpected success makes the check fail.

```bash
container run --rm --network none --no-dns \
  docker.io/library/alpine:3.24 sh -eu -c '
assert_probe_fails() {
  probe_name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $probe_name unexpectedly succeeded" >&2
    exit 1
  fi
  echo "PASS: $probe_name failed as expected"
}

for required_command in ip nslookup wget; do
  if ! command -v "$required_command" >/dev/null; then
    echo "FAIL: required command not found: $required_command" >&2
    exit 1
  fi
done

interface_names=$(ls /sys/class/net)
if [ "$interface_names" != lo ]; then
  echo "FAIL: expected only loopback; found: $interface_names" >&2
  exit 1
fi
echo "PASS: loopback is the only interface"

ipv4_default_route=$(ip -4 route show default)
ipv6_default_route=$(ip -6 route show default)
if [ -n "$ipv4_default_route$ipv6_default_route" ]; then
  echo "FAIL: found an IPv4 or IPv6 default route" >&2
  exit 1
fi
echo "PASS: no IPv4 or IPv6 default route"

assert_probe_fails "DNS lookup" nslookup example.com
assert_probe_fails "hostname access" wget -q -T 2 -O /dev/null http://example.com
assert_probe_fails "public IPv4 route" ip -4 route get 1.1.1.1
assert_probe_fails "public IPv6 route" ip -6 route get 2606:4700:4700::1111

for address in 10.0.0.1 172.16.0.1 192.168.0.1 169.254.169.254; do
  assert_probe_fails "$address route" ip -4 route get "$address"
done

echo "PASS: offline containment verified"
'
```

`ip route get` avoids treating a closed remote port as proof of containment.

## Account for current CLI gaps

Check `container --version` and `container help run` because the project evolves
quickly. In Apple `container` 1.3.1, the run interface exposes capability,
non-root user, read-only filesystem, network, tmpfs, CPU, memory, and `ulimit`
controls, but no documented `no-new-privileges`, seccomp, or process-count flag.

When `no-new-privileges` remains unavailable:

- Run as non-root and drop all capabilities unless a specific one is required.
- For images you control, remove unneeded SUID/SGID executables during the image
  build. This reduces one escalation path but is not equivalent to the kernel's
  `no_new_privs` control.
- Treat arbitrary third-party images as higher risk and avoid granting them
  writable host mounts unless the workflow truly needs one.

## Resolve local images deliberately

Use `container image ls --format json` or `container image inspect` to confirm
that the intended local tag maps to the expected image, then run the local tag.
Do not assume that a raw `sha256:...` argument means a local image ID.

An Apple issue that remains open for the 1.3.1 audit documents that in version
1.1.0, raw `sha256:...` and some
locally built `name:tag@sha256:...` references can miss local lookup and fall
back to Docker Hub. Container network flags apply to the guest workload, not
the host-side image lookup that precedes it. On affected versions, verify the
local image identity separately and invoke its tag.

## Validate, promote, and restore

- Write into a temporary run directory, destroy the container, and independently
  validate output structure, file types, sizes, and content on the host. Promote
  only approved files into the final destination.
- Resolve and check cleanup targets before deletion. Avoid broad globs or paths
  derived from unchecked workload output.
- Record whether the system service and builder were running before the task.
  Start only what is needed and stop only components the task started. Parse the
  builder's reported state; a successful status-command exit is not proof that
  the builder is running.

## Sources

- [Apple 1.3.1 technical overview](https://github.com/apple/container/blob/1.3.1/docs/technical-overview.md)
- [Apple 1.3.1 command reference](https://github.com/apple/container/blob/1.3.1/docs/command-reference.md)
- [Apple 1.3.1 mounts and volumes](https://github.com/apple/container/blob/1.3.1/docs/volumes.md)
- [Apple local digest lookup issue](https://github.com/apple/container/issues/1962)
- [NIST SP 800-190, Application Container Security Guide](https://csrc.nist.gov/pubs/sp/800/190/final)
- [Linux kernel `no_new_privs` documentation](https://www.kernel.org/doc/html/latest/userspace-api/no_new_privs.html)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
