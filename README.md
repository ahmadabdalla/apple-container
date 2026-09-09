# apple-container

An [Agent Skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
that gives agents a command-first guide for Apple's `container` CLI on Apple
Silicon macOS. It covers OCI workflows, services, builds, maintenance,
container machines, the experimental Kubernetes plugin, troubleshooting, and
the boundary with Docker tooling.

The skill captures operational learnings, gotchas, and execution flows so an
agent can use a proven fast path instead of repeatedly probing the environment
or creating avoidable back-and-forth.

## Install

### As a skill (works with any agent)

```bash
npx skills add ahmadabdalla/apple-container
```

> No `npx`? Install [Node.js](https://nodejs.org/) (includes `npm` and `npx`),
> or run `npm install -g skills` then `skills add ahmadabdalla/apple-container`.
> This pulls the latest from `main`.

### Manually (Claude Code)

```bash
cp -R skills/apple-container ~/.claude/skills/apple-container
```

Claude loads the skill automatically when a task matches its description.

## Usage

Ask in natural language; the skill activates on its own.

```text
Is Apple container installed and running?
Run an alpine container and print the kernel version
Publish a local web service on 127.0.0.1:18080 and verify it
My container exits right after start, help me debug it
Show what is using Apple container disk space and safely prune it
Create a persistent Linux development environment with container machine
Set up an experimental local Kubernetes cluster
Is Apple container enough for this, or do I need Docker Desktop?
```

## What it does

- Checks install and service status; installs or starts the service.
- Runs and builds OCI images with ports, mounts, networks, and volumes.
- Audits storage and uses supported remove/prune flows without corrupting
  snapshots or retained state.
- Covers persistent Linux environments through `container machine`.
- Covers the experimental `container k8s` local cluster plugin.
- Troubleshoots command, service, image, builder, network, and port failures.
- Hardens security-sensitive runs and restores prior service/builder state.
- Frames the Apple `container` versus Docker tooling tradeoff.

It does not present Apple `container` as a full Docker replacement for Compose,
Docker socket/API compatibility, Dev Containers, Testcontainers, mature
Kubernetes integration, or team-standard Docker behavior.

## Requirements

- Apple Silicon macOS 26+; install the latest stable Apple `container` release.
- Optional Homebrew for install; `curl` and `lsof` for checks.
- Internet access for pulling OCI images.

## Layout

```text
skills/apple-container
├── SKILL.md
├── scripts
│   ├── verify-offline.sh
│   ├── verify-offline-guest.sh
│   └── verify-readonly-bind.sh
└── references
    ├── current-features.md
    ├── local-services.md
    ├── maintenance.md
    ├── security-sensitive-runs.md
    ├── smoke-tests.md
    └── troubleshooting.md
```

`SKILL.md` keeps the core fast paths concise. Detailed execution flows load only
when a task needs them, preserving low token use without losing accumulated
operational knowledge.

## License

[MIT](LICENSE).
