#!/usr/bin/env bash

# --- Determine absolute paths robustly ---
# Get the directory where *this* script is located
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the repository root (project directory containing archlive/)
if command -v git &>/dev/null && git rev-parse --show-toplevel &>/dev/null; then
    # Inside a Git repository – use the top‑level directory
    export REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    # Fallback: walk up until we find archlive/profiledef.sh
    CURRENT_DIR="$SCRIPT_DIR"
    while [[ "$CURRENT_DIR" != "/" ]]; do
        if [[ -f "$CURRENT_DIR/archlive/profiledef.sh" ]]; then
            export REPO_ROOT="$CURRENT_DIR"
            break
        fi
        CURRENT_DIR="$(dirname "$CURRENT_DIR")"
    done
    # If still not found, fallback to GitHub workspace or current directory
    if [[ -z "${REPO_ROOT:-}" ]]; then
        export REPO_ROOT="${GITHUB_WORKSPACE:-$SCRIPT_DIR}"
    fi
fi

export PROFILE_DIR="$REPO_ROOT/archlive"
export WORK_DIR="/tmp/archiso-tmp"
export OUTPUT_DIR="$REPO_ROOT"
export OUT_DIR="${OUTPUT_DIR}"
export TEMP_MNT="${PROFILE_DIR}/TEMPMNT"
export PKG_CACHE_DIR="${PROFILE_DIR}/airootfs/root/archscripts-repo"
export RECIPES_DIR="${PROFILE_DIR}/airootfs/root/ArchScripts/recipes"
