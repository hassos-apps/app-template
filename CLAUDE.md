# CLAUDE.md

This is the **HassOS Apps — App Template** repository. It provides a skeleton for building Home Assistant add-ons under the [hassos-apps](https://github.com/hassos-apps) organization.

## Repository structure

```
.
├── setup.sh               # Interactive setup script — run once to initialize a new app
├── renovate.json          # Renovate config (auto-updates Dockerfile base image)
├── __APP_SLUG__/          # Template app directory — renamed by setup.sh
│   ├── Dockerfile
│   ├── config.yaml        # HA add-on manifest
│   ├── build.yaml         # Multi-arch build config
│   ├── apparmor.txt
│   ├── DOCS.md
│   ├── CHANGELOG.md
│   ├── icon.png           # 128×128
│   ├── logo.png           # 250×100
│   ├── translations/
│   └── rootfs/
│       └── etc/s6-overlay/s6-rc.d/
│           ├── __APP_SLUG__/        # Main long-running service
│           │   ├── run              # Start the process (exec pattern)
│           │   ├── finish           # Cleanup on stop
│           │   ├── type             # "longrun"
│           │   └── dependencies.d/
│           ├── init-__APP_SLUG__/   # One-shot init service
│           │   ├── run              # Setup/config before main service
│           │   ├── type             # "oneshot"
│           │   └── up
│           └── user/contents.d/     # Enables both services
```

## Placeholder system

All files use these placeholders, replaced by `setup.sh`:

| Placeholder | Example value |
|---|---|
| `__APP_NAME__` | `My App` |
| `__APP_SLUG__` | `my-app` |
| `__APP_DESCRIPTION__` | `A short description` |
| `__HA_ADDON_ID__` | `local_my_app` (hyphens → underscores, prefixed with `local_`) |
| `__YEAR__`, `__MONTH__`, `__DAY__` | `2026`, `03`, `19` |

When editing template files, preserve these placeholders exactly. Do not replace them with literal values.

## Docker / Alpine conventions

- Base image: `ghcr.io/hassio-addons/base` (Alpine-based)
- Package manager: `apk add --no-cache`
- Pin package versions explicitly (e.g. `jq=1.8.1-r0`) — required by hadolint
- Dockerfile uses `hadolint ignore=DL3006` for the `FROM` line because the base image uses an ARG
- Target architectures: `amd64`, `aarch64`

## s6-overlay service pattern

- The **init** service (`init-__APP_SLUG__`) runs once at startup for configuration setup
- The **main** service (`__APP_SLUG__`) is the long-running process
- The `run` script for the main service must use `exec` to replace the shell so s6 can supervise and signal correctly:
  ```bash
  exec /usr/bin/__APP_SLUG__ "${options[@]}"
  ```
- Use `bashio::config 'option_name'` to read options from `config.yaml`
- Use `bashio::log.info`, `bashio::log.warning`, etc. for logging

## config.yaml conventions

Required fields:

| Field | Notes |
|---|---|
| `name` | Human-readable app title |
| `version` | Must match the Docker image tag when using `image` |
| `slug` | Unique, URI-friendly identifier within the repository |
| `description` | One-line description |
| `arch` | List: `amd64`, `aarch64`, `armhf`, `armv7`, `i386` |

Common optional fields:

| Field | Notes |
|---|---|
| `startup` | `initialize` / `system` / `services` / `application` (default) / `once` |
| `boot` | `auto` (default) / `manual` / `manual_only` |
| `init` | Set to `false` — s6-overlay handles init |
| `backup` | `hot` (default, runs while add-on is active) / `cold` |
| `ingress` | `true` to enable the built-in reverse proxy |
| `ingress_port` | Port the app listens on for ingress (default `8099`) |
| `ingress_entry` | Entry path for ingress (default `/`) |
| `watchdog` | Health-check URL, e.g. `http://[HOST]:[PORT:8099]/` |
| `homeassistant_api` | `true` to allow access to HA Core API |
| `hassio_api` | `true` to allow access to Supervisor API |
| `auth_api` | `true` to enable HA authentication backend |
| `map` | Volume mounts: `ssl`, `share`, `homeassistant_config`, etc. |
| `ports` | Port mappings, e.g. `"8080/tcp": 8080` |
| `webui` | URL template shown in the UI, e.g. `http://[HOST]:[PORT:8080]/` |

- Always define `log_level` as an option with schema `list(trace|debug|info|notice|warning|error|fatal)?`
- Image naming: `ghcr.io/hassos-apps/__APP_SLUG__-{arch}`

### Schema types for `options` / `schema`

| Type | Example |
|---|---|
| `str` | Any string |
| `password` | Hidden in UI |
| `email` | Validated email |
| `url` | Validated URL |
| `port` | Integer 1–65535 |
| `bool` | `true`/`false` |
| `int(min,max)` | `int(1,100)` |
| `float(min,max)` | `float(0.1,1.0)` |
| `match(regex)` | `match(^[a-z]+$)` |
| `list(a\|b\|c)` | Enum |
| `device` | Hardware device path |
| Append `?` | Makes a field optional with no default |

## Security

From the [official security docs](https://developers.home-assistant.io/docs/apps/security/):

- Apps run in **protection mode** by default — do not disable it unless absolutely required
- Security rating scale is 1–6 (6 = most secure); aim for the highest rating compatible with the app's needs
- Use the minimum required API role:
  - `default` — read-only info calls
  - `homeassistant` — HA Core API access
  - `backup` — backup endpoints
  - `manager` — CLI tools and extended rights
  - `admin` — full access (avoid unless necessary)
- Always provide a custom `apparmor.txt` profile
- Map directories as `read_only: true` when write access is not needed
- Avoid running on the host network
- Request only the hardware flags actually needed (`gpio`, `usb`, `uart`, `audio`, `video`)
- Do not store credentials; use `auth_api: true` and HA's authentication backend instead

### Ingress auth headers

When accessed via Supervisor ingress, these headers identify the authenticated user — do not trust them from external requests:

- `X-Remote-User-Id`
- `X-Remote-User-Name`
- `X-Remote-User-Display-Name`

## Communication

From the [official communication docs](https://developers.home-assistant.io/docs/apps/communication/):

### Home Assistant Core API

Requires `homeassistant_api: true` in config.yaml:

```bash
curl -sSL \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  http://supervisor/core/api/states
```

WebSocket: `ws://supervisor/core/websocket`

### Supervisor API

Requires `hassio_api: true`:

```bash
curl -sSL \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  http://supervisor/
```

### Inter-add-on networking

- Add-ons communicate by hostname: `{REPO}_{SLUG}` (underscores converted to hyphens for DNS)
- Locally installed add-ons use `local` as the repo identifier, e.g. `local-my-app`

### Services (MQTT, MySQL)

```bash
# Read MQTT broker details provided by another add-on
MQTT_HOST=$(bashio::services mqtt "host")
MQTT_PORT=$(bashio::services mqtt "port")
MQTT_USER=$(bashio::services mqtt "username")
MQTT_PASS=$(bashio::services mqtt "password")
```

## Testing locally

From the [official testing docs](https://developers.home-assistant.io/docs/apps/testing/):

- Recommended: VS Code devcontainer (`devcontainer.json` + `.vscode/tasks.json`) — access at `http://localhost:7123/`
- To build locally instead of pulling from registry: **comment out the `image` key** in `config.yaml`
- All `stdout` / `stderr` output goes to Docker logs, visible in the Supervisor panel
- For hardware testing: copy files to `/addons` on a real HA device via Samba or SSH

## Versioning and changelog

- Versions follow [Semantic Versioning](https://semver.org/)
- CHANGELOG.md follows [Keep a Changelog](https://keepachangelog.com/) format
- GitHub Releases are the source of truth for releases

## What NOT to do

- Do not replace placeholders manually — they are managed by `setup.sh`
- Do not remove `setup.sh` (it removes itself after running)
- Do not use `latest` or unpinned tags in Dockerfile `apk add` calls
- Do not use shell init scripts instead of s6-overlay
- Do not disable protection mode without explicit justification
- Do not request `admin` API role unless the app truly requires it
- Do not map directories as writable when read-only is sufficient