#!/usr/bin/env bash
# gather_packages.sh - Collect packages and merge into archlive/packages.x86_64

set -e -u

# --- Determine base directory ---
if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    BASE_DIR="$GITHUB_WORKSPACE"
else
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# --- Source utilities if they exist ---
if [[ -f "${BASE_DIR}/utilities/directories.sh" ]]; then
    source "${BASE_DIR}/utilities/directories.sh"
else
    RECIPES_DIR="${BASE_DIR}/recipes"
    PACKAGES_FILE="${BASE_DIR}/archlive/packages.x86_64"
fi

if [[ -f "${BASE_DIR}/utilities/banned_recipes.sh" ]]; then
    source "${BASE_DIR}/utilities/banned_recipes.sh"
else
    BANNED_RECIPES=""
fi

# --- Read existing packages from file (if any) ---
declare -A existing_packages
if [[ -f "$PACKAGES_FILE" ]]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        # Extract package name (first word, strip whitespace)
        pkg=$(echo "$line" | awk '{print $1}')
        existing_packages["$pkg"]=1
    done < "$PACKAGES_FILE"
    echo "==> Found ${#existing_packages[@]} existing packages in $PACKAGES_FILE"
fi

# --- Gather packages from recipes ---
ALL_PACKAGES=""

if [[ -d "$RECIPES_DIR" ]]; then
    echo "==> Gathering packages from recipes in $RECIPES_DIR..."
    for recipe_path in $(find "$RECIPES_DIR" -name "*.sh" | sort); do
        recipe_name=$(basename "$recipe_path")
        # Skip banned recipes
        if [[ " ${BANNED_RECIPES} " == *" ${recipe_name} "* ]]; then
            echo "  -> Skipping banned recipe: $recipe_name"
            continue
        fi
        source "$recipe_path"
        if [[ -n "${RECIPE_PKGS:-}" ]]; then
            echo "  -> $recipe_name adds: $RECIPE_PKGS"
            ALL_PACKAGES="$ALL_PACKAGES $RECIPE_PKGS"
        else
            echo "  -> Warning: $recipe_name did not define RECIPE_PKGS"
        fi
        unset RECIPE_PKGS
    done
else
    echo "==> No recipes directory found. Using fallback source."
    # Fallback: if there's no recipes, we assume the packages file is already complete.
    # Or we could read from an alternative source; here we do nothing.
fi

# Trim whitespace
ALL_PACKAGES=$(echo $ALL_PACKAGES | xargs)

if [[ -z "$ALL_PACKAGES" ]]; then
    echo "==> No new packages from recipes. Nothing to add."
    exit 0
fi

# --- Determine which packages are missing ---
missing_packages=()
for pkg in $ALL_PACKAGES; do
    if [[ -z "${existing_packages[$pkg]:-}" ]]; then
        missing_packages+=("$pkg")
    fi
done

if [[ ${#missing_packages[@]} -eq 0 ]]; then
    echo "==> All packages from recipes are already in $PACKAGES_FILE."
    exit 0
fi

# --- Append missing packages to the file ---
echo "==> Adding ${#missing_packages[@]} missing package(s) to $PACKAGES_FILE"
{
    echo ""
    echo "# Packages added by gather_packages.sh on $(date)"
    for pkg in "${missing_packages[@]}"; do
        echo "$pkg"
    done
} >> "$PACKAGES_FILE"

echo "==> Done. Updated $PACKAGES_FILE"
