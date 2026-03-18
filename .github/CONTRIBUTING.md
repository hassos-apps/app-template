# Contributing to __APP_NAME__

> This app is part of [HassOS Apps](https://github.com/hassos-apps) — a curated ecosystem of purpose-built Home Assistant apps.

Thanks for your interest in contributing!

## Getting started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run linters locally:
   ```bash
   hadolint __APP_SLUG__/Dockerfile
   yamllint __APP_SLUG__/config.yaml __APP_SLUG__/build.yaml
   shellcheck __APP_SLUG__/rootfs/**/*.sh
   ```
5. Test locally with a Docker build:
   ```bash
   docker build -t __APP_SLUG__-test __APP_SLUG__/
   ```
6. Commit your changes and open a PR

## Conventions

- Follow [Keep a Changelog](https://keepachangelog.com/) for CHANGELOG.md
- Use [Semantic Versioning](https://semver.org/) for version bumps
- Pin Alpine package versions in Dockerfile
- Use `bashio` for reading options and logging
- Use `exec` in longrun service scripts

## Reporting issues

Use the [issue templates](https://github.com/hassos-apps/app-__APP_SLUG__/issues/new/choose) to report bugs or request features.
