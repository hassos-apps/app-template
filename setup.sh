#!/usr/bin/env bash
# =============================================================================
# HassOS Apps — App Template Setup Script
# Replaces all placeholders and renames directories for a new app.
# =============================================================================
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       HassOS Apps — App Setup         ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ── Gather input ─────────────────────────────────────────────────────────────

read -rp "$(echo -e "${BOLD}App name${NC} (e.g. My App): ")" APP_NAME
if [[ -z "${APP_NAME}" ]]; then
  echo -e "${RED}Error: App name cannot be empty${NC}" >&2
  exit 1
fi

read -rp "$(echo -e "${BOLD}App slug${NC} (e.g. my-app): ")" APP_SLUG
if [[ -z "${APP_SLUG}" ]]; then
  echo -e "${RED}Error: App slug cannot be empty${NC}" >&2
  exit 1
fi
# Validate slug format
if [[ ! "${APP_SLUG}" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo -e "${RED}Error: Slug must be lowercase, start with a letter, and use only a-z, 0-9, hyphens${NC}" >&2
  exit 1
fi

read -rp "$(echo -e "${BOLD}Description${NC} (short, one line): ")" APP_DESCRIPTION
if [[ -z "${APP_DESCRIPTION}" ]]; then
  echo -e "${RED}Error: Description cannot be empty${NC}" >&2
  exit 1
fi

# Derive HA addon ID (replace hyphens with underscores)
HA_ADDON_ID="local_${APP_SLUG//-/_}"

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)

echo ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "  Name:        ${BOLD}${APP_NAME}${NC}"
echo -e "  Slug:        ${BOLD}${APP_SLUG}${NC}"
echo -e "  Description: ${BOLD}${APP_DESCRIPTION}${NC}"
echo -e "  HA ID:       ${BOLD}${HA_ADDON_ID}${NC}"
echo -e "  Date:        ${BOLD}${YEAR}-${MONTH}-${DAY}${NC}"
echo ""

read -rp "$(echo -e "${BOLD}Proceed?${NC} [Y/n] ")" CONFIRM
if [[ "${CONFIRM,,}" == "n" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""

# ── Rename directories ───────────────────────────────────────────────────────

echo -e "${CYAN}Renaming directories...${NC}"

# Rename s6-overlay service directories (deepest first)
if [[ -d "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/init-__APP_SLUG__" ]]; then
  mv "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/init-__APP_SLUG__" \
     "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/init-${APP_SLUG}"
fi

if [[ -d "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/__APP_SLUG__" ]]; then
  mv "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/__APP_SLUG__" \
     "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/${APP_SLUG}"
fi

# Rename user/contents.d marker files
if [[ -f "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/init-__APP_SLUG__" ]]; then
  mv "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/init-__APP_SLUG__" \
     "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/init-${APP_SLUG}"
fi

if [[ -f "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/__APP_SLUG__" ]]; then
  mv "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/__APP_SLUG__" \
     "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/${APP_SLUG}"
fi

# Rename dependency marker files
if [[ -f "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/${APP_SLUG}/dependencies.d/init-__APP_SLUG__" ]]; then
  mv "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/${APP_SLUG}/dependencies.d/init-__APP_SLUG__" \
     "__APP_SLUG__/rootfs/etc/s6-overlay/s6-rc.d/${APP_SLUG}/dependencies.d/init-${APP_SLUG}"
fi

# Rename the main app directory
mv "__APP_SLUG__" "${APP_SLUG}"

echo -e "  ${GREEN}✓${NC} Directories renamed"

# ── Replace placeholders in files ────────────────────────────────────────────

echo -e "${CYAN}Replacing placeholders...${NC}"

# Find all text files and replace placeholders
# Exclude .git, binary files (png)
find . -type f \
  -not -path './.git/*' \
  -not -name '*.png' \
  -not -name 'setup.sh' \
  -print0 | while IFS= read -r -d '' file; do
  if file --mime-type "$file" | grep -q 'text/'; then
    sed -i '' \
      -e "s|__APP_NAME__|${APP_NAME}|g" \
      -e "s|__APP_SLUG__|${APP_SLUG}|g" \
      -e "s|__APP_DESCRIPTION__|${APP_DESCRIPTION}|g" \
      -e "s|__HA_ADDON_ID__|${HA_ADDON_ID}|g" \
      -e "s|__YEAR__|${YEAR}|g" \
      -e "s|__MONTH__|${MONTH}|g" \
      -e "s|__DAY__|${DAY}|g" \
      "$file" 2>/dev/null || true
  fi
done

echo -e "  ${GREEN}✓${NC} Placeholders replaced"

# ── Replace template README with app README ──────────────────────────────────

echo -e "${CYAN}Generating app README...${NC}"

cat > README.md << HEREDOC
# ${APP_NAME}

![Project Stage][project-stage-shield]
![License][license-shield]

[![Open your Home Assistant instance and show the dashboard of an app.][my-ha-badge]][my-ha-url]

${APP_DESCRIPTION}

## About

A Home Assistant app by [HassOS Apps](https://github.com/hassos-apps).

For full documentation, see [DOCS.md](./${APP_SLUG}/DOCS.md).

## Installation

1. Add the HassOS Apps repository to your Home Assistant instance:

   [![Add repository to my Home Assistant][repository-badge]][repository-url]

2. Search for "**${APP_NAME}**" in the app store and click "Install".

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE.md](LICENSE.md)

---

> Part of **[HassOS Apps](https://github.com/hassos-apps)** — a curated ecosystem of purpose-built Home Assistant apps, crafted with structure, clarity and long-term reliability.

[project-stage-shield]: https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg
[license-shield]: https://img.shields.io/github/license/hassos-apps/app-${APP_SLUG}.svg
[my-ha-badge]: https://my.home-assistant.io/badges/supervisor_addon.svg
[my-ha-url]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=${HA_ADDON_ID}&repository_url=https%3A%2F%2Fgithub.com%2Fhassos-apps%2Frepository
[repository-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fhassos-apps%2Frepository
HEREDOC

echo -e "  ${GREEN}✓${NC} README generated"

# ── Cleanup ──────────────────────────────────────────────────────────────────

echo -e "${CYAN}Cleaning up...${NC}"
rm -f setup.sh
echo -e "  ${GREEN}✓${NC} Setup script removed"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}✓ Setup complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Replace ${BOLD}${APP_SLUG}/icon.png${NC} (128×128) and ${BOLD}${APP_SLUG}/logo.png${NC} (250×100)"
echo -e "  2. Edit ${BOLD}${APP_SLUG}/Dockerfile${NC} to install your dependencies"
echo -e "  3. Edit ${BOLD}${APP_SLUG}/rootfs/etc/s6-overlay/s6-rc.d/${APP_SLUG}/run${NC}"
echo -e "  4. Edit ${BOLD}${APP_SLUG}/config.yaml${NC} to define options and schema"
echo -e "  5. Edit ${BOLD}${APP_SLUG}/DOCS.md${NC} with user documentation"
echo -e "  6. Commit and push:"
echo -e "     ${CYAN}git add -A && git commit -m 'feat: initialize ${APP_NAME}' && git push${NC}"
echo ""
