#!/bin/sh
# Take luci-app-footstrap-updater's released package as it is.
#
# Upstream's own CI builds it through the OpenWrt SDK. The feed distributes exactly
# what they published and adds only its own signature.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/upstream.sh"

# A prebuilt package is architecture-independent, so it goes where owfeed puts a
# noarch build and is picked up by `owfeed sign` and `owfeed index` unchanged.
DEST="${1:-dist}/noarch"
mkdir -p "$DEST"

url="https://github.com/${REPO}/releases/download/v${VERSION%-r*}/${ARTIFACT}"
echo ">> $ARTIFACT"
curl -fsSL --proto '=https' --tlsv1.2 -o "$DEST/$ARTIFACT" "$url"

got="$(sha256sum "$DEST/$ARTIFACT" | cut -d' ' -f1)"
[ "$got" = "$SHA256" ] || { echo "$url: sha256 $got, pinned $SHA256" >&2; rm -f "$DEST/$ARTIFACT"; exit 1; }
