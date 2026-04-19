#!/usr/bin/env bash

# --- Determine paths ---
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$SCRIPT_DIR"

# If running in GitHub Actions, use GITHUB_WORKSPACE
if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    export REPO_ROOT="$GITHUB_WORKSPACE"
fi

export PROFILE_DIR="$REPO_ROOT/archlive"
export WORK_DIR="/tmp/archiso-tmp"
export OUTPUT_DIR="$REPO_ROOT"
export OUT_DIR="${OUTPUT_DIR}"
export TEMP_MNT="${PROFILE_DIR}/TEMPMNT"
export PKG_CACHE_DIR="${PROFILE_DIR}/airootfs/root/pkg"
export RECIPES_DIR="${PROFILE_DIR}/airootfs/root/ArchScripts/recipes"
