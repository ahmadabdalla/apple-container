# apple-container

An [Agent Skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
that turns Claude into a command-first guide for Apple's `container` CLI on
Apple Silicon macOS: install and start the service, run OCI containers, publish
ports, bind mount files, build images, troubleshoot failures, and decide when
Apple `container` is enough versus Docker Desktop.

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
Is Apple container enough for this, or do I need Docker Desktop?
```

## What it does

- Checks install and service status; installs or starts the service.
- Runs OCI containers, publishes local ports, bind mounts host files.
- Builds small images with `container build`.
- Troubleshoots command, service, image, network, and port issues.
- Frames the Apple `container` versus Docker Desktop tradeoff.

It does not present Apple `container` as a full Docker Desktop replacement for
Compose, socket compatibility, Dev Containers, Testcontainers, or Kubernetes.

## Requirements

- Apple Silicon macOS, Apple `container` CLI 1.0 or later.
- Optional Homebrew for install; `curl` and `lsof` for checks.
- Internet access for pulling OCI images.

## Layout

```text
skills/apple-container
├── SKILL.md
└── references
    ├── local-services.md
    ├── smoke-tests.md
    └── troubleshooting.md
```

`SKILL.md` holds the core framework. Reference files load on demand, keeping
token use low.

## License

[MIT](LICENSE).
