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

## Account for current CLI gaps

Check `container --version` and `container help run` because the project evolves
quickly. In Apple `container` 1.2.0, the run interface exposes capability,
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

An open Apple issue documents that in version 1.1.0, raw `sha256:...` and some
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

- [Apple technical overview](https://github.com/apple/container/blob/main/docs/technical-overview.md)
- [Apple command reference](https://github.com/apple/container/blob/main/docs/command-reference.md)
- [Apple mounts and volumes](https://github.com/apple/container/blob/main/docs/volumes.md)
- [Apple local digest lookup issue](https://github.com/apple/container/issues/1962)
- [NIST SP 800-190, Application Container Security Guide](https://csrc.nist.gov/pubs/sp/800/190/final)
- [Linux kernel `no_new_privs` documentation](https://www.kernel.org/doc/html/latest/userspace-api/no_new_privs.html)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
