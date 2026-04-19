# Project Guidelines

## Code Style
- Use kebab-case for script names (e.g., actions_build.sh, customize_airootfs.sh)
- Use SNAKE_CASE for environment variables (e.g., RECIPE_PKGS, DESKTOP_ENV)
- Ensure scripts have executable permissions (755)

## Architecture
MIKAOS builds custom Arch Linux ISOs with modular recipes. Key components:
- ISO profile in `/archlive/`
- Installation scripts in `/archlive/airootfs/root/ArchScripts/`
- Recipes for packages in `recipes/` subdirs

See [README.md](README.md) for overview.

## Build and Test
- Build ISO: `./actions_build.sh`
- Test: Mount ISO and verify bootloaders, or use `qemu-system-x86_64 -cdrom mikaos.iso -boot d -m 2G`

## Conventions
- Recipes export `RECIPE_PKGS` variable for package lists
- Configuration via `env.sh` variables (USERNAME, DESKTOP_ENV, etc.)
- Error handling with `set -e` and `|| true` for non-critical failures
- Avoid installing multiple desktop managers simultaneously