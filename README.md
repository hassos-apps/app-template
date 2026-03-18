# HassOS Apps — App Template

> Template repository for creating new [HassOS Apps](https://github.com/hassos-apps).

## Quick Start

### 1. Create your repo

Click **[Use this template](https://github.com/hassos-apps/app-template/generate)** → name it `app-{your-slug}`.

### 2. Run the setup script

```bash
git clone https://github.com/hassos-apps/app-{your-slug}.git
cd app-{your-slug}
./setup.sh
```

The script will ask for your app name, slug, and description, then rename all placeholders and directories automatically.

### 3. Customize

- Replace `{slug}/icon.png` (128×128) and `{slug}/logo.png` (250×100) with your app's images
- Edit `{slug}/Dockerfile` to install your app's dependencies
- Edit `{slug}/rootfs/etc/s6-overlay/s6-rc.d/` service scripts
- Edit `{slug}/config.yaml` to define your app's options and schema
- Edit `{slug}/DOCS.md` with user-facing documentation
- Edit `{slug}/apparmor.txt` with app-specific security rules
- Edit `{slug}/translations/en.yaml` with option labels

### 4. Configure CI/CD

Add the `DISPATCH_TOKEN` secret to your repo (or use the org-level secret if available):
```bash
gh secret set DISPATCH_TOKEN -R hassos-apps/app-{your-slug}
```

### 5. Release

```bash
# Push to main → triggers edge build
git push origin main

# Create a release → triggers stable build
gh release create v1.0.0 --generate-notes
```

## What's Included

```
app-template/
├── .github/
│   ├── workflows/
│   │   ├── ci.yaml                    # CI on PRs (lint + build)
│   │   ├── deploy.yaml                # Deploy on push/release
│   │   ├── release-drafter.yaml       # Auto-draft release notes
│   │   └── stale.yaml                 # Auto-close stale issues
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yaml            # Structured bug report
│   │   └── feature_request.yaml       # Feature request form
│   ├── CODEOWNERS                     # Auto-assign reviewers
│   ├── CONTRIBUTING.md                # Contributor guidelines
│   ├── PULL_REQUEST_TEMPLATE.md       # PR checklist
│   ├── SECURITY.md                    # Security policy
│   ├── labels.yaml                    # GitHub label definitions
│   └── release-drafter.yaml           # Release notes config
├── __APP_SLUG__/                      # ← renamed by setup.sh
│   ├── config.yaml                    # App metadata and options
│   ├── build.yaml                     # Per-arch base images
│   ├── Dockerfile                     # Container build
│   ├── DOCS.md                        # User docs (shown in HA UI)
│   ├── CHANGELOG.md                   # Keep a Changelog
│   ├── apparmor.txt                   # AppArmor security profile
│   ├── icon.png                       # 128×128 placeholder
│   ├── logo.png                       # 250×100 placeholder
│   ├── translations/en.yaml           # English UI translations
│   └── rootfs/etc/s6-overlay/s6-rc.d/
│       ├── user/contents.d/           # Service registration
│       ├── init-__APP_SLUG__/         # Oneshot init service
│       └── __APP_SLUG__/              # Longrun daemon service
├── .editorconfig
├── .gitignore
├── .hadolint.yaml
├── .shellcheckrc
├── .yamllint
├── LICENSE.md
├── renovate.json
└── setup.sh                           # Interactive setup script
```

## Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `__APP_NAME__` | Display name | `My App` |
| `__APP_SLUG__` | URI-friendly slug | `my-app` |
| `__APP_DESCRIPTION__` | Short description | `Does something useful` |
| `__HA_ADDON_ID__` | HA identifier | `local_my_app` |
| `__YEAR__` | Current year | `2026` |
| `__MONTH__` | Current month | `03` |
| `__DAY__` | Current day | `18` |

## Conventions

- Base image: `ghcr.io/hassio-addons/base:20.0.1` (Alpine 3.23, s6-overlay v3, bashio)
- `init: false` in config.yaml (required for s6-overlay v3)
- Options read via `bashio::config` at runtime
- Persistent data in `/data/`
- Pin Alpine package versions in Dockerfile
- Use `exec` in longrun run scripts

---

> Part of **[HassOS Apps](https://github.com/hassos-apps)** — a curated ecosystem of purpose-built Home Assistant apps, crafted with structure, clarity and long-term reliability.
