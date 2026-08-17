#!/usr/bin/env bash
# Publish Pillarius ISO builds to GitHub Releases and refresh the
# downloads page (index.html) on PillarTree/Pillarius.
#
# Usage:  ./publish.sh [ISO_DIR]
#
# ISO_DIR defaults to ../Pillarius-live/output
set -euo pipefail

cd "$(dirname "$0")"

REPO="PillarTree/Pillarius"
ISO_DIR="${1:-$(dirname "$PWD")/Pillarius-live/output}"
[ -d "$ISO_DIR" ] || { echo "error: ISO_DIR not found: $ISO_DIR" >&2; exit 1; }

shopt -s nullglob
ISOS=("$ISO_DIR"/*.iso)
[ "${#ISOS[@]}" -gt 0 ] || { echo "error: no .iso files in $ISO_DIR" >&2; exit 1; }

echo "publishing to $REPO from $ISO_DIR"
for iso in "${ISOS[@]}"; do
    name=$(basename "$iso")
    # pillarius-<variant>-<date>-amd64.iso -> tag pillarius-<date>-<variant>
    tag=$(echo "$name" | sed -E 's/^pillarius-([a-z]+)-([0-9]+)-amd64\.iso$/pillarius-\2-\1/')
    echo "--- $name -> release $tag"

    if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
        echo "release exists, uploading missing assets"
        for asset in "$iso" "$iso.sha256"; do
            [ -f "$asset" ] || continue
            base=$(basename "$asset")
            if ! gh release view "$tag" --repo "$REPO" --json assets \
                --jq ".assets[] | select(.name == \"$base\")" >/dev/null 2>&1; then
                gh release upload "$tag" "$asset" --repo "$REPO"
            fi
        done
    else
        echo "creating release"
        gh release create "$tag" "$iso" "$iso.sha256" \
            --repo "$REPO" \
            --title "Pillarius $name" \
            --notes "Pillarius live ISO: $name

SHA256: $(cat "$iso.sha256" | cut -d' ' -f1)"
    fi
done

echo "--- refreshing downloads page"
./update-index.sh

echo "done. site: https://pillartree.github.io/Pillarius/"